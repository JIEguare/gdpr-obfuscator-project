# IAM Role for Lambda Function
# This role allows the Lambda function to assume the role and access AWS services.
# The assume role policy allows the Lambda service to assume this role.
# The s3:HeadObject in the aws_iam policy document is needed to check if the object exists in the S3 bucket.
# The s3:PutObject is needed to upload the object to the S3 bucket.
# The s3:GetObject is needed to download the object from the S3 bucket.
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

# CREATING AND ATTACHING CLOUDWATCH POLICES
# The policy document defines the permissions for the Lambda function to access CloudWatch.
data "aws_iam_policy_document" "got_cloudwatch_policy_document" {
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogGroup"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
}
}

resource "aws_iam_policy" "got_cloudwatch_policy" {
  name = "lambda_cloudwatch_policy"
  policy = data.aws_iam_policy_document.got_cloudwatch_policy_document.json
}

resource "aws_iam_role_policy_attachment" "got_cloudwatch_policy_attachment" {
  role = aws_iam_role.got_lambda_role.name
  policy_arn = aws_iam_policy.got_cloudwatch_policy.arn
}

# IAM Role for Step Functions
# This role allows Step Functions to assume the role and access AWS services.
# The assume role policy allows the Step Functions service to assume this role.
# The policy document defines the permissions for Step Functions to access Lambda, CloudWatch, S3, and SNS.
resource "aws_iam_role" "iam_for_got_sfn" {
  name = "iam-role-for-got-sfn"
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
                        "states.amazonaws.com",
                        "events.amazonaws.com",
                        "scheduler.amazonaws.com"
                    ]
                }
            }
        ]
    }
EOF
}


resource "aws_iam_policy_attachment" "got_sfn_lambda_execution" {
  name       = "got_sfn_lambda_execution_attachment"
  roles      = [aws_iam_role.iam_for_got_sfn.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}
resource "aws_iam_policy_attachment" "got_sfn_cloudwatch_execution" {
  name       = "got_sfn_cloudwatch_execution_attachment"
  roles      = [aws_iam_role.iam_for_got_sfn.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_policy_attachment" "got_sfn_s3_execution" {
  name       = "sfn_s3_execution_attachment"
  roles      = [aws_iam_role.iam_for_got_sfn.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_policy_attachment" "got_sfn_sns_execution" {
  name       = "sfn_sns_execution_attachment"
  roles      = [aws_iam_role.iam_for_got_sfn.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_policy" "got_eventbridge_access_policy" {
    name = "got-eventbridge-access-policy"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "states:StartExecution"
            ],
            "Resource": [
                "${aws_sfn_state_machine.got_sfn_state_machine.arn}"
            ]
        }
    ]
}
EOF
}

# IAM Role for EventBridge Scheduler
# This role allows EventBridge Scheduler to assume the role and access AWS services.
# The assume role policy allows the EventBridge Scheduler service to assume this role.
# The policy document defines the permissions for EventBridge Scheduler to start execution of Step Functions.

resource "aws_iam_role" "got_eventbridge_scheduler_iam_role" {
  name = "got-eventbridge-scheduler-role"
  assume_role_policy  = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "scheduler.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "got_eventbridge_scheduler" {
  policy_arn = aws_iam_policy.got_eventbridge_access_policy.arn
  role       = aws_iam_role.got_eventbridge_scheduler_iam_role.name
}

# IAM Role for SNS Publish
# This role allows the Lambda function to publish messages to SNS and access CloudWatch logs.
# The policy document defines the permissions for the Lambda function to publish messages to SNS and access CloudWatch logs.

resource "aws_iam_role_policy" "got_sns_publish_policy" {
  name = "sns-publish"
  role = aws_iam_role.got_lambda_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "iam:ListAccountAliases",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}