locals {
  secret_reference = var.access_key_secretsmanager_reference != "" ? split(":", var.access_key_secretsmanager_reference) : []
}

resource "aws_iam_role" "orchestrator_agent_execution_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]

  dynamic "inline_policy" {
    for_each = var.access_key_secretsmanager_reference != "" ? ["SecretsManagerAccessKey"] : []
    content {
      name = "root"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = [
              "secretsmanager:GetSecretValue",
            ]
            Effect = "Allow"
            Resource = [format("arn:aws:secretsmanager:%s:%s:secret:%s",
              element(local.secret_reference, 3),
              element(local.secret_reference, 4),
              element(local.secret_reference, 6)
              )
            ]
          },
        ]
      })
    }
  }

  tags = merge(var.tags, var.default_tags)
}

resource "aws_iam_role" "orchestrator_agent_task_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  inline_policy {
    name   = "root"
    policy = data.aws_iam_policy_document.task_policy.json
  }

  tags = merge(var.tags, var.default_tags)
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}
