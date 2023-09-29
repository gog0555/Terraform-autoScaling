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
