# Define the required providers and their versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"   # Specifies the source of the AWS provider
      version = "~> 5.0"          # Ensures compatibility with version 5.x of the AWS provider
    }
  }

  # Configure the backend for storing Terraform state remotely in an S3 bucket
  backend "s3" {
    bucket = "gdpr-obfuscator-terraform-state-bucket"  # Name of the S3 bucket used for state storage
    key    = "reader_app/terraform.tfstate"            # Path to the state file within the bucket
    region = "eu-west-2"                               # AWS region where the S3 bucket is located
  }
}

# Configure the AWS provider with the specified region
provider "aws" {
  region = "eu-west-2"  # Sets the default AWS region for resources
}
