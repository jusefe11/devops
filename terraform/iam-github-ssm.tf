resource "aws_iam_role_policy" "github_ssm_deploy" {
  name = "hola-juan-devops-github-ssm-deploy"
  role = "devops-juan"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ssm:SendCommand"
        ]

        Resource = [
          aws_instance.devops.arn,
          "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation"
        ]

        Resource = "*"
      }
    ]
  })
}