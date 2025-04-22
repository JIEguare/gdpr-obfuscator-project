resource "aws_iam_role" "got_lambda_role" {
  name = "got_lambda_role"
  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                }
            }
        ]
    }
    EOF
}

data "aws_iam_policy_document" "s3_bucket_document" {
  statement {
    actions = ["s3:GetObject", "s3:PutObject", "s3:HeadObject"]
    resources = ["${aws_s3_bucket.pii_file_bucket.arn}/*"]
    }
}

data "aws_iam_policy_document" "bucket_action_document" {
  statement {
    actions = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.pii_file_bucket.arn}"]
    }
}

resource "aws_iam_policy" "s3_policy" {
  name = "lambda_s3_policy"
  policy = data.aws_iam_policy_document.s3_bucket_document.json
}

resource "aws_iam_policy" "bucket_policy" {
  name = "bucket_action_document_policy"
  policy = data.aws_iam_policy_document.bucket_action_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role = aws_iam_role.got_lambda_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "bucket_policy_attachment" {
  role = aws_iam_role.got_lambda_role.name
  policy_arn = aws_iam_policy.bucket_policy.arn
}