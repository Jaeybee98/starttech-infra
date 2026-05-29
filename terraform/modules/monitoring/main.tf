# Centralized Log Group for the Golang Backend App
resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "/aws/starttech/backend-application"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-backend-logs"
    Environment = "production"
  }
}

# Metric Alarm to trigger if ASG instances experience high strain
resource "aws_cloudwatch_metric_alarm" "cpu_high_alarm" {
  alarm_name          = "${var.project_name}-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ec2 cpu utilization exceeding performance safety parameters"
  actions_enabled     = false # Set up target actions if mapping to SNS queues later
}
