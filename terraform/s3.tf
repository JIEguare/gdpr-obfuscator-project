# Creates an S3 bucket to store files containing Personally Identifiable Information (PII)
resource "aws_s3_bucket" "pii_file_bucket" {
  bucket         = "personally-identifiable-info-bucket"  # Explicit name for the S3 bucket
  force_destroy  = false                                  # Prevents bucket deletion if it contains objects

  tags = {
    Name        = "PII bucket"                            # Tag to identify the bucket
    Environment = "Dev"                                   # Tag indicating the environment
  }
}

# resource "aws_s3_object" "student_file_object" {
#   bucket = aws_s3_bucket.pii_file_bucket.id
#   key    = "new_data/student_data.csv"
#   source = "/Users/jayeguare/PORTFOLIO/gdpr-obfuscator-project/data/students_data.csv"
# }

# Creates an S3 bucket with a generated name prefix for storing application code (e.g., Lambda functions)
resource "aws_s3_bucket" "got_code_bucket" {
  bucket_prefix = "obfuscator-code-bucket-"               # Prefix for generating a unique bucket name
  force_destroy = false                                   # Prevents deletion if the bucket has contents

  tags = {
    Name        = "got code bucket"                        # Tag to identify the bucket
    Environment = "Dev"                                    # Tag indicating the environment
  }
}

# Uploads a ZIP file containing the Lambda function code to the 'got_code_bucket'
resource "aws_s3_object" "got_lambda" {
  bucket = aws_s3_bucket.got_code_bucket.id               # Reference to the code bucket
  key    = "got_lamda_code"                               # Key (filename in the bucket)
  source = "${path.module}/../src/gdpr_obfuscator_tool.zip"  # Path to the ZIP file to upload
}