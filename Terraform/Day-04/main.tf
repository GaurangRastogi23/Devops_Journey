terraform{
    required_providers {
     aws={
       source= "hashicorp/aws"
     }
    }
}

provider "aws" {
    region = "ap-south-1"
}

resource "aws_instance" "web" {
  ami = "ami-01a00762f46d584a1"
  instance_type = "t3.micro"

  tags = {
    Name = "Backend"
  }
}

