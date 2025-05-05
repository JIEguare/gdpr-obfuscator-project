# Creates an AWS Step Functions state machine to orchestrate Lambda execution for masking PII data
resource "aws_sfn_state_machine" "got_sfn_state_machine" {
  name     = "got-sfn-state-machine"                     # Name of the state machine
  role_arn = aws_iam_role.iam_for_got_sfn.arn            # IAM role that Step Functions uses to execute this state machine

  # Definition block written in Amazon States Language (JSON)
  definition = <<EOF
{
  "Comment": "GOT state machine responsible for masking PII data by invoking Lambda function", 
  "StartAt": "Got Lambda Invoke",                                                              
  "States": {
    "Got Lambda Invoke": {
      "Type": "Task",                                                                           
      "Resource": "arn:aws:states:::lambda:invoke",                                            
      "OutputPath": "$.Payload",                                                                
      "Parameters": {
        "Payload.$": "$",                                                                        
        "FunctionName": "${aws_lambda_function.gdpr_obfuscator_tool.arn}"                   
      },
      "Retry": [                                                                                 
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,          
          "MaxAttempts": 3,              
          "BackoffRate": 2,             
          "JitterStrategy": "FULL"       
        }
      ],
      "End": true                       
    }
  }
}
EOF
}
