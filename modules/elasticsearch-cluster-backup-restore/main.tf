# ------------------------------------------------------------------------------------------------------------------
# ELASTICSEARCH DOMAIN
# ------------------------------------------------------------------------------------------------------------------

data "aws_elasticsearch_domain" "elasticsearch_domain" {
  domain_name = var.elasticsearch_domain_name
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY S3 BUCKET TO STORE CLUSTER SNAPSHOTS
# ------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "s3_bucket" {
  count = var.skip_creating_bucket ? 0 : 1

  bucket = var.bucket_name
  acl    = "private"

  tags = merge(
    {
      Name = var.bucket_name
    },
    var.tags
  )
}

data "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name

  depends_on = [
    aws_s3_bucket.s3_bucket
  ]
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY IAM ROLE THAT ALLOWS AMAZON ELASTICSEARCH DOMAIN TO TAKE SNAPSHOTS TO THE S3 BUCKET
# ------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "elasticsearch_domain_iam_role" {
  name        = "${var.elasticsearch_domain_name}-${var.bucket_name}"
  description = "The iam role for ${var.elasticsearch_domain_name} elasticsearch domain."

  assume_role_policy = data.aws_iam_policy_document.elasticsearch_domain_assume_role_policy_document.json

  tags = merge(
    {
      Name = var.elasticsearch_domain_name
    },
    var.tags
  )
}

data "aws_iam_policy_document" "elasticsearch_domain_assume_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "es.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "elasticsearch_domain_snapshots_iam_role_policy" {
  name = "${var.elasticsearch_domain_name}-snapshots"
  role = aws_iam_role.elasticsearch_domain_iam_role.name

  policy = data.aws_iam_policy_document.elasticsearch_domain_snapshots_iam_policy_document.json
}

data "aws_iam_policy_document" "elasticsearch_domain_snapshots_iam_policy_document" {
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
# DEPLOY A KEY PAIR FOR ELASTICSEARCH BASTION EC2 INSTANCE
# ------------------------------------------------------------------------------------------------------------------

resource "aws_key_pair" "elasticsearch_bastion_key_pair" {
  key_name   = var.elasticsearch_bastion_instance_name
  public_key = file("${path.root}/${var.elasticsearch_bastion_instance_public_key}")

  tags = merge(
    {
      Name = var.elasticsearch_bastion_instance_name
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY THE SECURITY GROUP FOR ELASTICSEARCH BASTION EC2 INSTANCE
# ------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "elasticsearch_bastion_security_group" {
  name        = var.elasticsearch_bastion_instance_name
  description = "The security group for ${var.elasticsearch_bastion_instance_name} instance."

  vpc_id = var.elasticsearch_bastion_instance_vpc

  tags = merge(
    {
      Name = var.elasticsearch_bastion_instance_name
    },
    var.tags
  )
}

resource "aws_security_group_rule" "allow_all_outbound_elasticsearch_bastion_security_group_rule" {
  type              = "egress"
  security_group_id = aws_security_group.elasticsearch_bastion_security_group.id
  description       = "allow all outbound communications from ${var.elasticsearch_bastion_instance_name} instance to the internet."

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_ssh_inbound_elasticsearch_bastion_security_group_rule" {
  type              = "ingress"
  security_group_id = aws_security_group.elasticsearch_bastion_security_group.id
  description       = "allow ssh inbound communications from ${join(",", var.elasticsearch_bastion_instance_ssh_cidr_blocks)} to the ${var.elasticsearch_bastion_instance_name} instance."

  from_port   = var.elasticsearch_bastion_instance_ssh_port
  to_port     = var.elasticsearch_bastion_instance_ssh_port
  protocol    = "tcp"
  cidr_blocks = var.elasticsearch_bastion_instance_ssh_cidr_blocks
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY A SECURITY GROUP RULE TO ALLOW ELASTICSEARCH BASTION EC2 INSTANCE TO ACCESS THE ELASTICSEARCH SERVICE DOMAIN
# ------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "allow_elasticsearch_bastion_to_elasticsearch_domain_http_security_group_rule" {
  type              = "ingress"
  security_group_id = var.elasticsearch_domain_security_group
  description       = "allow communication on http port from elasticsearch bastion instance to the elasticsearch domain."

  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.elasticsearch_bastion_security_group.id
}

resource "aws_security_group_rule" "allow_elasticsearch_bastion_to_elasticsearch_domain_https_security_group_rule" {
  type              = "ingress"
  security_group_id = var.elasticsearch_domain_security_group
  description       = "allow communication on https port from elasticsearch bastion instance to the elasticsearch domain."

  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.elasticsearch_bastion_security_group.id
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY ELASTICSEARCH BASTION EC2 INSTANCE
# ------------------------------------------------------------------------------------------------------------------

data "aws_ami" "amazon_linux_2_ami" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["*amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "elasticsearch_bastion_instance" {
  ami           = data.aws_ami.amazon_linux_2_ami.id
  instance_type = var.elasticsearch_bastion_instance_type

  availability_zone = var.elasticsearch_bastion_instance_availability_zone
  subnet_id         = var.elasticsearch_bastion_instance_subnet

  key_name                    = aws_key_pair.elasticsearch_bastion_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.elasticsearch_bastion_security_group.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/user-data.sh")

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.elasticsearch_bastion_instance_root_volume_size
    delete_on_termination = true
  }

  tags = merge(
    {
      Name = var.elasticsearch_bastion_instance_name
    },
    var.tags
  )

  volume_tags = merge(
    {
      Name = var.elasticsearch_bastion_instance_name
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY IAM ROLE FOR BACKUP LAMBDA FUNCTION TO CALL ELASTICSEARCH APIS TO TAKE A SNAPSHOT
# ------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "backup_lambda_iam_role" {
  name        = var.backup_function_name
  description = "The iam role for ${var.backup_function_name} function."

  assume_role_policy = data.aws_iam_policy_document.backup_lambda_assume_role_policy_document.json

  tags = merge(
    {
      Name = var.backup_function_name
    },
    var.tags
  )
}

data "aws_iam_policy_document" "backup_lambda_assume_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "backup_lambda_iam_role_policy" {
  name = var.backup_function_name
  role = aws_iam_role.backup_lambda_iam_role.name

  policy = data.aws_iam_policy_document.backup_lambda_iam_policy_document.json
}

data "aws_iam_policy_document" "backup_lambda_iam_policy_document" {
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
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]
    resources = ["*"]
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
# DEPLOY SECURITY GROUP FOR BACKUP LAMBDA FUNCTION TO ACCESS ELASTICSEARCH CLUSTER INSIDE VPC
# ------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "backup_lambda_security_group" {
  name        = var.backup_function_name
  description = "The security group for ${var.backup_function_name} function."

  vpc_id = data.aws_elasticsearch_domain.elasticsearch_domain.vpc_options[0].vpc_id

  tags = merge(
    {
      Name = var.backup_function_name
    },
    var.tags
  )
}

resource "aws_security_group_rule" "backup_lambda_allow_all_outbound_security_group_rule" {
  type              = "egress"
  security_group_id = aws_security_group.backup_lambda_security_group.id
  description       = "allow all outbound communications from the backup lambda function to the internet."

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_backup_lambda_to_elasticsearch_domain_https_security_group_rule" {
  type              = "ingress"
  security_group_id = var.elasticsearch_domain_security_group
  description       = "allow communication on https port from backup lambda to the elasticsearch domain."

  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backup_lambda_security_group.id
}

resource "aws_security_group_rule" "allow_backup_lambda_to_elasticsearch_domain_http_security_group_rule" {
  type              = "ingress"
  security_group_id = var.elasticsearch_domain_security_group
  description       = "allow communication on http port from backup lambda to the elasticsearch domain."

  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backup_lambda_security_group.id
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY BACKUP LAMBDA FUNCTION
# ------------------------------------------------------------------------------------------------------------------

data "archive_file" "backup_lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-functions/backup"
  output_path = "${path.module}/lambda-functions/backup_lambda_code.zip"
}

resource "aws_lambda_function" "backup_lambda_function" {
  function_name = var.backup_function_name
  description   = "A lambda function to take a snapshot of ${var.elasticsearch_domain_name} elasticsearch cluster and save it ${var.bucket_name} s3 bucket."

  role = aws_iam_role.backup_lambda_iam_role.arn

  runtime          = "nodejs12.x"
  filename         = "${path.module}/lambda-functions/backup_lambda_code.zip"
  source_code_hash = data.archive_file.backup_lambda_code.output_base64sha256
  handler          = "index.handler"

  memory_size = var.backup_function_memory_size
  timeout     = var.backup_function_timeout

  vpc_config {
    subnet_ids         = data.aws_elasticsearch_domain.elasticsearch_domain.vpc_options[0].subnet_ids
    security_group_ids = [aws_security_group.backup_lambda_security_group.id]
  }

  environment {
    variables = {
      BUCKET_ID                         = data.aws_s3_bucket.s3_bucket.id
      BUCKET_REGION                     = var.bucket_region
      ELASTICSEARCH_DOMAIN_ENDPOINT     = data.aws_elasticsearch_domain.elasticsearch_domain.endpoint
      ELASTICSEARCH_DOMAIN_IAM_ROLE_ARN = aws_iam_role.elasticsearch_domain_iam_role.arn
      SLACK_WEBHOOK_URL                 = var.notifications_slack_webhook_url
    }
  }

  tags = merge(
    {
      Name = var.backup_function_name
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY CLOUDWATCH EVENT TO AUTOMATICALLY TRIGGER THE BACKUP LAMBDA FUNCTION
# ------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "backup_cloudwatch_event_rule" {
  name        = var.backup_function_name
  description = "The scheduled cloudwatch event that triggers the ${var.backup_function_name} lambda function every ${var.backup_function_schedule_time}."

  schedule_expression = var.backup_function_schedule_time
  is_enabled          = var.skip_scheduling_backup_function ? false : true

  tags = merge(
    {
      Name = var.backup_function_name
    },
    var.tags
  )
}

resource "aws_cloudwatch_event_target" "backup_cloudwatch_event_target" {
  rule      = aws_cloudwatch_event_rule.backup_cloudwatch_event_rule.name
  target_id = var.backup_function_name
  arn       = aws_lambda_function.backup_lambda_function.arn
}

resource "aws_lambda_permission" "backup_cloudwatch_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup_cloudwatch_event_rule.arn
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY IAM ROLE FOR RESTORE LAMBDA FUNCTION TO CALL ELASTICSEARCH APIS TO RESTORE A SNAPSHOT
# ------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "restore_lambda_iam_role" {
  name        = var.restore_function_name
  description = "The iam role for ${var.restore_function_name} function."

  assume_role_policy = data.aws_iam_policy_document.restore_lambda_assume_role_policy_document.json

  tags = merge(
    {
      Name = var.restore_function_name
    },
    var.tags
  )
}

data "aws_iam_policy_document" "restore_lambda_assume_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "restore_lambda_iam_role_policy" {
  name = var.restore_function_name
  role = aws_iam_role.restore_lambda_iam_role.name

  policy = data.aws_iam_policy_document.restore_lambda_iam_policy_document.json
}

data "aws_iam_policy_document" "restore_lambda_iam_policy_document" {
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
      "es:ESHttpPost",
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
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]
    resources = ["*"]
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
# DEPLOY SECURITY GROUP FOR RESTORE LAMBDA FUNCTION TO ACCESS ELASTICSEARCH CLUSTER INSIDE VPC
# ------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "restore_lambda_security_group" {
  name        = var.restore_function_name
  description = "The security group for ${var.restore_function_name} function."

  vpc_id = data.aws_elasticsearch_domain.elasticsearch_domain.vpc_options[0].vpc_id

  tags = merge(
    {
      Name = var.restore_function_name
    },
    var.tags
  )
}

resource "aws_security_group_rule" "restore_lambda_allow_all_outbound_security_group_rule" {
  type              = "egress"
  security_group_id = aws_security_group.restore_lambda_security_group.id
  description       = "allow all outbound communications from the restore lambda function to the internet."

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_restore_lambda_to_elasticsearch_domain_https_security_group_rule" {
  type              = "ingress"
  security_group_id = var.elasticsearch_domain_security_group
  description       = "allow communication on https port from restore lambda to the elasticsearch domain."

  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.restore_lambda_security_group.id
}

resource "aws_security_group_rule" "allow_restore_lambda_to_elasticsearch_domain_http_security_group_rule" {
  type              = "ingress"
  security_group_id = var.elasticsearch_domain_security_group
  description       = "allow communication on http port from restore lambda to the elasticsearch domain."

  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.restore_lambda_security_group.id
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY RESTORE LAMBDA FUNCTION
# ------------------------------------------------------------------------------------------------------------------

data "archive_file" "restore_lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-functions/restore"
  output_path = "${path.module}/lambda-functions/restore_lambda_code.zip"
}

resource "aws_lambda_function" "restore_lambda_function" {
  function_name = var.restore_function_name
  description   = "A lambda function to restore a snapshot of ${var.elasticsearch_domain_name} elasticsearch cluster from ${var.bucket_name} s3 bucket."

  role = aws_iam_role.restore_lambda_iam_role.arn

  runtime          = "nodejs12.x"
  filename         = "${path.module}/lambda-functions/restore_lambda_code.zip"
  source_code_hash = data.archive_file.restore_lambda_code.output_base64sha256
  handler          = "index.handler"

  memory_size = var.restore_function_memory_size
  timeout     = var.restore_function_timeout

  vpc_config {
    subnet_ids         = data.aws_elasticsearch_domain.elasticsearch_domain.vpc_options[0].subnet_ids
    security_group_ids = [aws_security_group.restore_lambda_security_group.id]
  }

  environment {
    variables = {
      BUCKET_ID                         = data.aws_s3_bucket.s3_bucket.id
      BUCKET_REGION                     = var.bucket_region
      ELASTICSEARCH_DOMAIN_ENDPOINT     = data.aws_elasticsearch_domain.elasticsearch_domain.endpoint
      ELASTICSEARCH_DOMAIN_IAM_ROLE_ARN = aws_iam_role.elasticsearch_domain_iam_role.arn
    }
  }

  tags = merge(
    {
      Name = var.restore_function_name
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY IAM ROLE FOR QUERY LAMBDA FUNCTION TO CALL ELASTICSEARCH APIS TO GET A SNAPSHOT STATUS
# ------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "query_lambda_iam_role" {
  name        = var.query_function_name
  description = "The iam role for ${var.query_function_name} function."

  assume_role_policy = data.aws_iam_policy_document.query_lambda_assume_role_policy_document.json

  tags = merge(
    {
      Name = var.query_function_name
    },
    var.tags
  )
}

data "aws_iam_policy_document" "query_lambda_assume_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "query_lambda_iam_role_policy" {
  name = var.query_function_name
  role = aws_iam_role.query_lambda_iam_role.name

  policy = data.aws_iam_policy_document.query_lambda_iam_policy_document.json
}

data "aws_iam_policy_document" "query_lambda_iam_policy_document" {
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
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]
    resources = ["*"]
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
# DEPLOY SECURITY GROUP FOR QUERY LAMBDA FUNCTION TO ACCESS ELASTICSEARCH CLUSTER INSIDE VPC
# ------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "query_lambda_security_group" {
  name        = var.query_function_name
  description = "The security group for ${var.query_function_name} function."

  vpc_id = data.aws_elasticsearch_domain.elasticsearch_domain.vpc_options[0].vpc_id

  tags = merge(
    {
      Name = var.query_function_name
    },
    var.tags
  )
}

resource "aws_security_group_rule" "query_lambda_allow_all_outbound_security_group_rule" {
  type              = "egress"
  security_group_id = aws_security_group.query_lambda_security_group.id
  description       = "allow all outbound communications from the query lambda function to the internet."

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_query_lambda_to_elasticsearch_domain_https_security_group_rule" {
  type              = "ingress"
  security_group_id = var.elasticsearch_domain_security_group
  description       = "allow communication on https port from query lambda to the elasticsearch domain."

  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.query_lambda_security_group.id
}

resource "aws_security_group_rule" "allow_query_lambda_to_elasticsearch_domain_http_security_group_rule" {
  type              = "ingress"
  security_group_id = var.elasticsearch_domain_security_group
  description       = "allow communication on http port from query lambda to the elasticsearch domain."

  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.query_lambda_security_group.id
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY QUERY LAMBDA FUNCTION
# ------------------------------------------------------------------------------------------------------------------

data "archive_file" "query_lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-functions/query"
  output_path = "${path.module}/lambda-functions/query_lambda_code.zip"
}

resource "aws_lambda_function" "query_lambda_function" {
  function_name = var.query_function_name
  description   = "A lambda function to query the snapshot API of ${var.elasticsearch_domain_name} elasticsearch cluster."

  role = aws_iam_role.query_lambda_iam_role.arn

  runtime          = "nodejs12.x"
  filename         = "${path.module}/lambda-functions/query_lambda_code.zip"
  source_code_hash = data.archive_file.query_lambda_code.output_base64sha256
  handler          = "index.handler"

  memory_size = var.query_function_memory_size
  timeout     = var.query_function_timeout

  vpc_config {
    subnet_ids         = data.aws_elasticsearch_domain.elasticsearch_domain.vpc_options[0].subnet_ids
    security_group_ids = [aws_security_group.query_lambda_security_group.id]
  }

  environment {
    variables = {
      BUCKET_ID                         = data.aws_s3_bucket.s3_bucket.id
      BUCKET_REGION                     = var.bucket_region
      ELASTICSEARCH_DOMAIN_ENDPOINT     = data.aws_elasticsearch_domain.elasticsearch_domain.endpoint
      ELASTICSEARCH_DOMAIN_IAM_ROLE_ARN = aws_iam_role.elasticsearch_domain_iam_role.arn
    }
  }

  tags = merge(
    {
      Name = var.query_function_name
    },
    var.tags
  )
}
