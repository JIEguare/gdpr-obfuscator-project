resource "aws_scheduler_schedule" "everyday" {
  name       = "everyday_schedule"
  group_name = "default"
 

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(24 hours)"
  schedule_expression_timezone = "Europe/London"

  target {
    arn      = aws_sfn_state_machine.got_sfn_state_machine.arn
    role_arn = aws_iam_role.got_eventbridge_scheduler_iam_role.arn
  
    input = jsonencode({
      file_to_obfuscate = var.file_to_obfuscate,
      pii_fields        = var.pii_fields
    })
  }
}