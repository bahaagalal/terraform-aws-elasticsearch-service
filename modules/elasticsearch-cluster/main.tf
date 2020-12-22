# ------------------------------------------------------------------------------------------------------------------
# CREATE ELASTICSEARCH CLUSTER DEFAULT SECURITY GROUP
# ------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "security_group" {
  name        = var.name
  description = "The security group for ${var.name} Elasticsearch cluster."

  vpc_id = var.vpc_id

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

resource "aws_security_group_rule" "allow_all_outbound_security_group_rule" {
  type              = "egress"
  security_group_id = aws_security_group.security_group.id
  description       = "allow all outbound communications from the cluster to the internet."

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE ELASTICSEARCH CLUSTER SERVICE LINKED ROLE FOR VPC ACCESS
# Amazon Elasticsearch requires a service-linked role to access the VPC, create the domain endpoint,
# and place network interfaces in a subnet of the VPC.
# ------------------------------------------------------------------------------------------------------------------

resource "aws_iam_service_linked_role" "iam_service_linked_role" {
  count = var.skip_creating_service_linked_role ? 0 : 1

  aws_service_name = "es.amazonaws.com"
  description      = "The VPC service linked role for Elasticsearch service."
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE ELASTICSEARCH CLUSTER
# ------------------------------------------------------------------------------------------------------------------

resource "aws_elasticsearch_domain" "elasticsearch_domain" {
  domain_name           = var.name
  elasticsearch_version = var.elasticsearch_version

  vpc_options {
    subnet_ids         = var.subnet_ids
    security_group_ids = concat([aws_security_group.security_group.id], var.additional_security_group_ids)
  }

  cluster_config {
    instance_type  = var.data_nodes_instance_type
    instance_count = var.data_nodes_instance_count

    dedicated_master_enabled = var.master_nodes_instance_count > 0 ? true : false
    dedicated_master_type    = var.master_nodes_instance_count > 0 ? var.master_nodes_instance_type : null
    dedicated_master_count   = var.master_nodes_instance_count > 0 ? var.master_nodes_instance_count : null

    warm_enabled = var.warm_nodes_instance_count > 0 ? true : false
    warm_type    = var.warm_nodes_instance_count > 0 ? var.warm_nodes_instance_type : null
    warm_count   = var.warm_nodes_instance_count > 0 ? var.warm_nodes_instance_count : null

    zone_awareness_enabled = length(var.availability_zones) > 1 ? true : false
    zone_awareness_config {
      availability_zone_count = length(var.availability_zones) == 2 ? 2 : 3
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = var.data_nodes_volume_size
  }

  encrypt_at_rest {
    enabled = false
  }

  node_to_node_encryption {
    enabled = false
  }

  domain_endpoint_options {
    enforce_https       = var.enforce_https
    tls_security_policy = "Policy-Min-TLS-1-0-2019-07"
  }

  snapshot_options {
    automated_snapshot_start_hour = var.snapshot_hour
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "indices.fielddata.cache.size"           = tostring(var.fielddata_cache)
    "indices.query.bool.max_clause_count"    = "1024"
  }

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE ELASTICSEARCH CLUSTER POLICY TO ALLOW ANONYMOUS ACCESS FROM THE AUTHORIZED SECURITY GROUPS INSIDE THE VPC
# ------------------------------------------------------------------------------------------------------------------

resource "aws_elasticsearch_domain_policy" "elasticsearch_domain_policy" {
  domain_name     = aws_elasticsearch_domain.elasticsearch_domain.domain_name
  access_policies = data.aws_iam_policy_document.elasticsearch_iam_policy_document.json
}

data "aws_iam_policy_document" "elasticsearch_iam_policy_document" {
  version = "2012-10-17"
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    effect = "Allow"
    actions = [
      "es:ESHttpHead",
      "es:ESHttpPost",
      "es:ESHttpGet",
      "es:ESHttpPatch",
      "es:ESHttpDelete",
      "es:ESHttpPut"
    ]
    resources = [
      "${aws_elasticsearch_domain.elasticsearch_domain.arn}/*"
    ]
  }
}
