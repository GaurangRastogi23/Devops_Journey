terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"

    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "my_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }

}

