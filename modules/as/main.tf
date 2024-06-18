#..................................asg..................................
#create launch-template
resource "aws_launch_template" "launch-template" {
  name = "launch-template"
  image_id = var.ami
  instance_type = var.instance_type
  vpc_security_group_ids = [var.client_sg_id]
  key_name = var.key_name
  #user_data = "s"
  tags = {  
    Name = "launch-template"
  }
}

#create auto scaling group
resource "aws_autoscaling_group" "asg" {
  name = "asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_cap
  health_check_grace_period = 300
  health_check_type         = var.asg_health_check_type #"ELB" or default EC2
  vpc_zone_identifier = [var.private_subnets_ids[0], var.private_subnets_ids[1]]
  target_group_arns   = [var.alb_tg_arn] 

  launch_template {   
    id = aws_launch_template.launch-template.id
    version = aws_launch_template.launch-template.latest_version
  }
  
# metrics for cloudwatch alarms 
#collect data/metrics > cloudwatch > cloudatch alarm & trigger action > call certain autoscaling_policy > scale up/down
enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

}

#create scale up policy 
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  policy_type            = "SimpleScaling"

  
}

#create scale up alarm
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "asg-scale-up-alarm"
  alarm_description   = "asg-scale-up-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70" # New instance will be created once CPU utilization is higher than 30 %
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.asg.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_up.arn]
}

#create scale down policy 
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = -1
  cooldown = 300
  policy_type = "SimpleScaling"

}

#create scale down alarm
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "asg-scale-down-alarm"
  alarm_description   = "asg-scale-down-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "7" # Instance will scale down when CPU utilization is lower than 7 %
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.asg.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_down.arn]
}