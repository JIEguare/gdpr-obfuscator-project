# Cloudwatch log group and log stream for the Lambda function
# This file creates a CloudWatch log group and log stream for the Lambda function
# and sets up a metric filter to count the number of errors in the logs.
# It also creates an SNS topic and subscription to send email alerts when the error count exceeds a threshold of 1.
# The log group and log stream are created with a retention period of 7 days.
# The metric filter is set to look for the pattern "ERROR" in the logs and count the number of occurrences.
# The SNS topic is created with the name "ErrorsOverThresholdLimit" and the subscription is set to send an email to the address specified in the variable "SNS_EMAIL".
# The CloudWatch metric alarm is created to trigger when the error count exceeds 1 within a 1-minute period.
# The alarm is set to send a notification to the SNS topic when it is triggered.
# The Lambda function is given permission to write logs to the CloudWatch log group.
resource "aws_cloudwatch_log_group" "got_lambda_function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.gdpr_obfuscator_tool.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

# Create a log stream for the Lambda function
resource "aws_cloudwatch_log_stream" "got_lambda_function_log_stream" {
  name = "got lambda function log stream"
  log_group_name = aws_cloudwatch_log_group.got_lambda_function_log_group.name
}

# Create a metric filter to count the number of errors in the logs
resource "aws_cloudwatch_log_metric_filter" "lambdaLogDataErrorCountMetricFilter" {
  name           = "got-log-metric"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.got_lambda_function_log_group.name
  metric_transformation {
    name      = "error count"
    namespace = "Lambda"
    value     = "1"

  }
  
}

# SNS Topic/Email Alert
resource "aws_sns_topic" "errorsOverThresholdLimit" {
  name = "ErrorsOverThresholdLimit"
}
resource "aws_sns_topic_subscription" "projectEmailSubscription" {
  topic_arn = aws_sns_topic.errorsOverThresholdLimit.arn
  protocol  = "email"
  endpoint  = var.SNS_EMAIL
}

# Create a CloudWatch metric alarm to trigger when the error count exceeds 1
#remember to set the dimensions to the Lambda function name.
resource "aws_cloudwatch_metric_alarm" "gotLambdaErrorsCountAlarm" {
  alarm_name                = "gotLambdaErrorsCountAlarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda" 
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 1
  alarm_description         = "major error(s) alarm"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.errorsOverThresholdLimit.arn]
  

  dimensions = {

    FunctionName = "${aws_lambda_function.gdpr_obfuscator_tool.function_name}"
  }
}

# Give the Lambda function permission to write logs to the CloudWatch log group
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gdpr_obfuscator_tool.function_name
  principal     = "logs.${var.AWS_REGION}.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.got_lambda_function_log_group.arn
}