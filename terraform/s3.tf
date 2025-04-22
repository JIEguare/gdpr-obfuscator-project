resource "aws_s3_bucket" "pii_file_bucket" {
  bucket_prefix = "personally-identifiable-info-bucket-"
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

  etag = filemd5("/Users/jayeguare/PORTFOLIO/gdpr-obfuscator-project/data/students_data.csv")
}