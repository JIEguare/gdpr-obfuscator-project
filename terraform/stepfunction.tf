# Creates an AWS Step Functions state machine to orchestrate Lambda execution for masking PII data
resource "aws_sfn_state_machine" "got_sfn_state_machine" {
  name     = "got-sfn-state-machine"                     # Name of the state machine
  role_arn = aws_iam_role.iam_for_got_sfn.arn            # IAM role that Step Functions uses to execute this state machine

  # Definition block written in Amazon States Language (JSON)
  definition = <<EOF
{
  "Comment": "GOT state machine responsible for masking PII data by invoking Lambda function",  // Description of the workflow
  "StartAt": "Got Lambda Invoke",                                                               // Entry point of the state machine
  "States": {
    "Got Lambda Invoke": {
      "Type": "Task",                                                                            // Indicates this state is a task (invokes a Lambda)
      "Resource": "arn:aws:states:::lambda:invoke",                                              // Built-in integration pattern for Lambda invocation
      "OutputPath": "$.Payload",                                                                 // Selects only the Payload from the Lambda output
      "Parameters": {
        "Payload.$": "$",                                                                        // Passes the entire input as the payload
        "FunctionName": "${aws_lambda_function.gdpr_obfuscator_tool.arn}"                        // ARN of the Lambda function to invoke
      },
      "Retry": [                                                                                 // Retry configuration for handling common Lambda errors
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,          // Initial wait time between retries
          "MaxAttempts": 3,              // Maximum number of retry attempts
          "BackoffRate": 2,              // Exponential backoff rate
          "JitterStrategy": "FULL"       // Adds randomness to retry timing to reduce contention
        }
      ],
      "End": true                        // Indicates the end of the state machine execution
    }
  }
}
EOF
}
