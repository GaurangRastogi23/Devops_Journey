terraform{
  required_providers {
    aws = {
      source = "hashicorp/aws"
}
}
}
provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-01a00762f46d584a1"
  instance_type = "t3.micro"

  tags = {
    Name = "terraform-learning"
  }
}