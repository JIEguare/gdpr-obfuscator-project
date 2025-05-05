# Defines the email address to which SNS notifications will be sent
variable "SNS_EMAIL" {
  description = "The email address to send SNS notifications to"
  type        = string  
}

# Defines the AWS region where all resources will be deployed
variable "AWS_REGION" {
  description = "The AWS region to deploy the resources in"
  type        = string  
}

# Specifies the S3 path to the file that contains PII data to be obfuscated
variable "file_to_obfuscate" {
  description = "The S3 file path to obfuscate"
  type        = string  
}

# Specifies a list of PII field names (e.g., "email_address", "name") that should be masked
variable "pii_fields" {
  description = "List of PII fields to obfuscate"
  type        = list(string)
}
