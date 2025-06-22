# 📊 CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "DevOpsAssignmentDashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 6,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.app_cluster.name, "ServiceName", aws_ecs_service.frontend_service.name ],
            [ "AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.app_cluster.name, "ServiceName", aws_ecs_service.backend_service.name ]
          ],
          period = 300,
          stat = "Average",
          region = var.aws_region,
          title = "ECS CPU & Memory"
        }
      }
    ]
  })
}

# 🚨 Alarm: Backend CPU
resource "aws_cloudwatch_metric_alarm" "backend_high_cpu" {
  alarm_name          = "BackendHighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Triggers when backend CPU > 70%"
  dimensions = {
    ClusterName = aws_ecs_cluster.app_cluster.name
    ServiceName = aws_ecs_service.backend_service.name
  }
  treat_missing_data = "notBreaching"
}

# 🚨 Alarm: Frontend Memory
resource "aws_cloudwatch_metric_alarm" "frontend_high_memory" {
  alarm_name          = "FrontendHighMemoryUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Triggers when frontend Memory > 75%"
  dimensions = {
    ClusterName = aws_ecs_cluster.app_cluster.name
    ServiceName = aws_ecs_service.frontend_service.name
  }
  treat_missing_data = "notBreaching"
}
