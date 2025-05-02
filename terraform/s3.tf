resource "aws_s3_bucket" "pii_file_bucket" {
  bucket = "personally-identifiable-info-bucket"
  force_destroy = false

  tags = {
    Name        = "PII bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "student_file_object" {
  bucket = aws_s3_bucket.pii_file_bucket.id
  key    = "new_data/student_data.csv"
  source = "/Users/jayeguare/PORTFOLIO/gdpr-obfuscator-project/data/students_data.csv"
}

resource "aws_s3_bucket" "got_code_bucket" {
  bucket_prefix = "obfuscator-code-bucket-"
  force_destroy = false

  tags = {
    Name = "got code bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "got_lambda" {
  bucket = aws_s3_bucket.got_code_bucket.id
  key = "got_lamda_code"
  source = "${path.module}/../src/gdpr_obfuscator_tool.zip"
  
}