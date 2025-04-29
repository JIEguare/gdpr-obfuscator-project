variable "SNS_EMAIL" {
  description = "the email address to send SNS notifications to"
  type = string
}

variable "AWS_REGION" {
  description = "the AWS region to deploy the resources in"
  type = string
  
  }

variable "file_to_obfuscate" {
  description = "The S3 file path to obfuscate"
  type        = string
}

variable "pii_fields" {
  description = "List of PII fields to obfuscate"
  type        = list(string)
}