resource "aws_cloudwatch_log_group" "got_lambda_function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.gdpr_obfuscator_tool.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_cloudwatch_log_stream" "got_lambda_function_log_stream" {
  name = "got lambda function log stream"
  log_group_name = aws_cloudwatch_log_group.got_lambda_function_log_group.name
}


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


# SNS TOPIC/ EMAIL ALERT
resource "aws_sns_topic" "errorsOverThresholdLimit" {
  name = "ErrorsOverThresholdLimit"
}
resource "aws_sns_topic_subscription" "projectEmailSubscription" {
  topic_arn = aws_sns_topic.errorsOverThresholdLimit.arn
  protocol  = "email"
  endpoint  = var.SNS_EMAIL
}

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

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gdpr_obfuscator_tool.function_name
  principal     = "logs.${var.AWS_REGION}.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.got_lambda_function_log_group.arn
}