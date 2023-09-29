resource "aws_launch_template" "template" {
  name_prefix   = "${var.env}-${var.name}-template"
  image_id      = var.instance_ami
  instance_type = var.instance_type

  vpc_security_group_ids = [var.ec2_sg_id]
  key_name = "terraform-dev"

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 8
      volume_type = "gp3"
      delete_on_termination = true
    }
  }
  user_data = base64encode(file("script.sh"))

  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2

  vpc_zone_identifier = [var.public_subnets[1], var.public_subnets[2]]


  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  tag {
    key = "Name"
    value = "${var.env}-${var.name}-autoscaling-group"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "autoscaling_policy" {
  name                   = "${var.env}-${var.name}-autoscaling-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
}

data "aws_iam_policy" "AmazonEC2RoleforSSM" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

data "aws_iam_policy_document" "ec2_assume_role" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type    = "Service"
            identifiers =["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "role" {
    name = "${var.env}-${var.name}-ssm-role"
    description = "Allows EC2 instances to call AWS services on your behalf."
    assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "profile" {
    name = "${var.env}-${var.name}-profile"
    path = "/"
    role = aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "attachment" {
    role = aws_iam_role.role.name
    policy_arn = data.aws_iam_policy.AmazonEC2RoleforSSM.arn
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name                = "${var.env}-${var.name}-cpu-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 40

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_group.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.autoscaling_policy.arn]
}
