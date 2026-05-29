# ==========================================
# 1. SECURITY GROUPS (Network Firewalls)
# ==========================================

# ALB Security Group (Public facing)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound HTTP public traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# EC2 Security Group (Private backend)
resource "aws_security_group" "instance_sg" {
  name        = "${var.project_name}-instance-sg"
  description = "Allow inbound traffic restricted ONLY to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Strict dependency
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Needed to talk to Mongo Atlas/GitHub/Updates
  }

  tags = { Name = "${var.project_name}-instance-sg" }
}

# ==========================================
# 2. IAM ROLE & PROFILE (CloudWatch Logging Access)
# ==========================================

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

# Attach standard Amazon CloudWatch policy for logs & metrics
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ==========================================
# 3. APPLICATION LOAD BALANCER (ALB)
# ==========================================

resource "aws_lb" "backend_alb" {
  name               = "${var.project_name}-backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.project_name}-backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    port                = "8080"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# ==========================================
# 4. LAUNCH TEMPLATE & AUTO SCALING GROUP
# ==========================================

# Fetch latest stable Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false # Securely placed in private subnets
    security_groups             = [aws_security_group.instance_sg.id]
  }

  # Simple initialization script to deploy the CloudWatch Agent daemon
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo dnf install -y amazon-cloudwatch-agent
              sudo amazon-cloudwatch-agent-ctl -a start
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "${var.project_name}-asg-"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.backend_tg.arn]

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# 5. ELASTICACHE REDIS CLUSTER
# ==========================================

# Redis Subnet Group (Assigns Redis strictly into Private Networks)
resource "aws_elasticache_subnet_group" "redis_subnet_gp" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

# Redis Firewall Rules
resource "aws_security_group" "redis_sg" {
  name        = "${var.project_name}-redis-sg"
  description = "Control port traffic access mapping into cache subnet shards"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg.id] # Only accept queries from backend servers
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-redis-sg" }
}

# Provisioning the Redis Cluster
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id        = "${var.project_name}-redis-cache"
  description                 = "ElastiCache cluster for application sessions and caching layer"
  node_type                   = "cache.t3.micro" # Keeps footprint within cost optimization targets
  num_cache_clusters          = 1
  parameter_group_name        = "default.redis7"
  port                        = 6379
  subnet_group_name           = aws_elasticache_subnet_group.redis_subnet_gp.name
  security_group_ids          = [aws_security_group.redis_sg.id]
  at_rest_encryption_enabled  = true
  transit_encryption_enabled = false # Disabled to allow seamless connection debugging during assessment tasks
}
