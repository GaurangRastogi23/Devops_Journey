terraform {
  backend "s3" {
    bucket = "gaurang-s3-bucket-2026"
    key    = "gaurang/terraform.tfstate"
    region = "ap-south-1"
  }
}
