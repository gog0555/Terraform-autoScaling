variable "env" {
  type    = string
  default = "env"
}

variable "name" {
  type    = string
  default = "name"
}

variable "cidr_block" {
  type    = string
  default = "cidr_block"
}

variable "subnets" {
  type = map(any)
  default = {
    public_subnets = {
      public-1 = {
        name = "public-1"
        cidr = "10.0.1.0/24"
        az   = "ap-northeast-1a"
      },
      public-2 = {
        name = "public-2"
        cidr = "10.0.2.0/24"
        az   = "ap-northeast-1c"
      },
      public-3 = {
        name = "public-3"
        cidr = "10.0.3.0/24"
        az   = "ap-northeast-1d"
      },
    }
  }
}

variable "instance_ami" {
  type    = string
  default = "ami-03a1b4db103179555"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}
