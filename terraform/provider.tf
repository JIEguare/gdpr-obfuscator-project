terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
    backend "s3" {
        bucket = "gdpr-obfuscator-terraform-state-bucket"
        key = "reader_app/terraform.tfstate"
        region = "eu-west-2"
    }
}

# Step to configure the AWS Provider
provider "aws" {
  region = "eu-west-2"
}