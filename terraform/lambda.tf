data "archive_file" "got_file" {
  type = "zip"
  output_file_mode = "0666"
  source_file = "${path.module}/../src/gdpr_obfuscator_tool.py"
  output_path = "${path.module}/../src/gdpr_obfuscator_tool.zip"
}

resource "aws_lambda_function" "gdpr_obfuscator_tool" {
  function_name = "gdpr_obfuscator_tool"
  handler = "gdpr_obfuscator_tool.lambda_handler"
  runtime = "python3.11"
  timeout = 60
  s3_bucket = aws_s3_bucket.got_code_bucket.id
  s3_key = aws_s3_object.got_lambda.key
  role = aws_iam_role.got_lambda_role.arn
  layers = ["arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:20"]
  memory_size = 500
}