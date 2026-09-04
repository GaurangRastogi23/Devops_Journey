variable "instance_type" {
  description = "It tell the type of instance"
  type        = string
}

variable "ami_id" {
  description = "It tells the ami id "
  type        = string

}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "instance_name" {
  description = "Name of EC2 instance"
  type        = string
}