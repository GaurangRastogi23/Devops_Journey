terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  alias  = "south"
  region = var.south_region
}

provider "aws" {
  alias  = "east"
  region = var.east_region
}

module "south_ec2" {
  source = "./modules/ec2"

  providers = {
    aws = aws.south
  }

  ami_id         = data.aws_ami.ubuntu_south.id
  instance_type  = var.instance_type
  instance_name  = "south-web"
  instance_count = var.instance_count
}

module "east_ec2" {
  source = "./modules/ec2"

  providers = {
    aws = aws.east
  }

  ami_id         = data.aws_ami.ubuntu_east.id
  instance_type  = var.instance_type
  instance_name  = "east-web"
  instance_count = 1
}