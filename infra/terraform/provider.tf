provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket         = "retrofun-terraform-state-bucket"
    key            = "retrofun_api/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

