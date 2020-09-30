# ------------------------------------------------------------------------------------------------------------------
# LOCALS
# ------------------------------------------------------------------------------------------------------------------

locals {
  tags = merge(
    {
      Role   = "Elasticsearch Snapshots"
      Domain = var.elasticsearch_domain
    },
    var.tags
  )
  lambda_filename = "snapshot_lambda_function.zip"
}

# ------------------------------------------------------------------------------------------------------------------
# ELASTICSEARCH DOMAIN
# ------------------------------------------------------------------------------------------------------------------

data "aws_elasticsearch_domain" "elasticsearch_domain" {
  domain_name = var.elasticsearch_domain
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE S3 BUCKET TO STORE SNAPSHOTS TO
# ------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "s3_bucket" {
  count = var.bucket_exists ? 0 : 1

  bucket = var.bucket
  acl    = "private"

  tags = merge(
    {
      Name = var.bucket
    },
    local.tags
  )
}

data "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket

  depends_on = [
    aws_s3_bucket.s3_bucket
  ]
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE IAM ROLE THAT DELEGATES PERMISSIONS TO AMAZON ELASTICSEARCH SERVICE
# ------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "elasticsearch_domain_iam_role" {
  name               = "${var.elasticsearch_domain}-elasticsearch-domain-iam-role"
  assume_role_policy = data.aws_iam_policy_document.elasticsearch_domain_assume_role_policy_document.json

  tags = local.tags
}

data "aws_iam_policy_document" "elasticsearch_domain_assume_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }
  }
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE IAM ROLE POLICY THAT ALLOWS THE AMAZON ELASTICSEARCH DOMAIN TO TAKE SNAPSHOTS TO THE S3 BUCKET
# ------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "elasticsearch_domain_snapshots_policy" {
  name   = "${var.elasticsearch_domain}-elasticsearch-domain-snapshots-policy"
  policy = data.aws_iam_policy_document.elasticsearch_domain_snapshots_policy_document.json
  role   = aws_iam_role.elasticsearch_domain_iam_role.name
}

data "aws_iam_policy_document" "elasticsearch_domain_snapshots_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      data.aws_s3_bucket.s3_bucket.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${data.aws_s3_bucket.s3_bucket.arn}/*"
    ]
  }
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE IAM ROLE THAT DELEGATES PERMISSIONS TO AMAZON LAMBDA FUNCTION
# ------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "lambda_iam_role" {
  name               = "${var.name}-lambda-iam-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_document.json

  tags = local.tags
}

data "aws_iam_policy_document" "lambda_assume_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE IAM ROLE POLICY THAT ALLOWS THE LAMBDA FUNCTION TO ACCESS THE AMAZON ELASTICSEARCH DOMAIN
# ------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "lambda_elasticsearch_http_policy" {
  name   = "${var.name}-lambda-elasticsearch-http-policy"
  policy = data.aws_iam_policy_document.lambda_elasticsearch_http_policy_document.json
  role   = aws_iam_role.lambda_iam_role.name
}

data "aws_iam_policy_document" "lambda_elasticsearch_http_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.elasticsearch_domain_iam_role.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "es:ESHttpPut",
      "es:ESHttpGet"
    ]
    resources = [
      "${data.aws_elasticsearch_domain.elasticsearch_domain.arn}/_snapshot*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE LAMBDA FUNCTION TO TRIGGER THE SNAPSHOT TASK ON THE ELASTICSEARCH DOMAIN
# ------------------------------------------------------------------------------------------------------------------

data "archive_file" "lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "${path.module}/files/${local.lambda_filename}"
}

resource "aws_lambda_function" "lambda_function" {
  function_name = var.name
  description   = "A lambda function to call the elasticsearch APIs on ${var.elasticsearch_domain} to perform snapshotting and backup related tasks."

  role = aws_iam_role.lambda_iam_role.arn

  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  reserved_concurrent_executions = 1

  runtime          = "nodejs12.x"
  filename         = "${path.module}/files/${local.lambda_filename}"
  source_code_hash = data.archive_file.lambda_code.output_base64sha256
  handler          = "index.handler"

  environment {
    variables = {
      REGION                        = var.region
      ELASTICSEARCH_DOMAIN_ENDPOINT = data.aws_elasticsearch_domain.elasticsearch_domain.endpoint
      BUCKET                        = data.aws_s3_bucket.s3_bucket.id
      ROLE                          = aws_iam_role.elasticsearch_domain_iam_role.arn
    }
  }

  tags = local.tags
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE SCHEDULED CLOUDWATCH EVENT TO TRIGGER THE LAMBDA FUNCTION
# ------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  name                = "${var.name}-lambda-cloudwatch-scheduled-event-rule"
  description         = "Trigger ${var.name} lambda function every ${var.schedule_time}"
  schedule_expression = var.schedule_time
  is_enabled          = var.enable_lambda_scheduled_event

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_target" {
  rule      = aws_cloudwatch_event_rule.cloudwatch_event_rule.name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda_function.arn

  input = jsonencode({
    indices = join(",", var.elasticsearch_indices)
  })
}

resource "aws_lambda_permission" "lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_rule.arn
}
