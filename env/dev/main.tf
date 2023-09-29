module "network" {
  source = "../../modules/network"

  env  = var.env
  name = var.name

  cidr_block = var.cidr_block
  subnets    = var.subnets
  vpc_id     = module.network.vpc_id
}


module "ec2" {
  source = "../../modules/ec2"

  env  = var.env
  name = var.name

  vpc_id         = module.network.vpc_id
  public_subnets = module.network.public_subnets

  instance_ami  = var.instance_ami
  instance_type = var.instance_type

  depends_on = [module.network]
}

module "autoscaling" {
  source = "../../modules/autoscaling"

  env  = var.env
  name = var.name

  instance_ami  = var.instance_ami
  instance_type = var.instance_type

  ec2_sg_id = module.ec2.ec2_sg_id
  public_subnets = module.network.public_subnets

  depends_on = [module.network]
}
