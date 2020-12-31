# ------------------------------------------------------------------------------------------------------------------
# DEPLOY AN ELASTICSEARCH CLUSTER FOR DEVELOPMENT
# This example shows how to use the elasticsearch-cluster module to create an Elasticsearch cluster using AWS Elasticsearch service.
# ------------------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This example has been developed with 0.13 syntax, which means it is not compatible with any versions below 0.13.
# ------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.13, < 0.14"
}

# ------------------------------------------------------------------------------------------------------------------
# AWS PROVIDER
# ------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.region
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY VPC TO HOST THE ELASTICSEARCH CLUSTER
# ------------------------------------------------------------------------------------------------------------------

module "vpc" {
  source = "git::git@github.com:crowdanalyzer/terraform-aws-vpc//modules/vpc-2tiers?ref=v1.0.0"

  name       = var.name
  cidr_block = var.vpc

  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY ELASTICSEARCH CLUSTER
# ------------------------------------------------------------------------------------------------------------------

module "development_cluster" {
  source = "../../modules/elasticsearch-cluster"

  name                  = var.name
  elasticsearch_version = var.elasticsearch_version

  vpc_id             = module.vpc.vpc_id
  availability_zones = var.availability_zones
  subnet_ids         = module.vpc.private_subnets_ids

  data_nodes_instance_type  = var.data_nodes_instance_type
  data_nodes_instance_count = var.data_nodes_instance_count

  skip_creating_service_linked_role = var.skip_creating_service_linked_role
}

# ------------------------------------------------------------------------------------------------------------------
# DEPLOY ELASTICSEARCH CLUSTER BACKUP AND RESTORE FUNCTIONS
# ------------------------------------------------------------------------------------------------------------------

module "development_cluster_backup_restore" {
  source = "../../modules/elasticsearch-cluster-backup-restore"

  bucket_name          = var.bucket_name
  bucket_region        = var.region
  skip_creating_bucket = var.skip_creating_bucket

  elasticsearch_domain_name           = module.development_cluster.name
  elasticsearch_domain_security_group = module.development_cluster.security_group

  elasticsearch_bastion_instance_name              = var.elasticsearch_bastion_instance_name
  elasticsearch_bastion_instance_type              = var.elasticsearch_bastion_instance_type
  elasticsearch_bastion_instance_public_key        = var.elasticsearch_bastion_instance_public_key
  elasticsearch_bastion_instance_availability_zone = var.availability_zones[0]
  elasticsearch_bastion_instance_vpc               = module.vpc.vpc_id
  elasticsearch_bastion_instance_subnet            = module.vpc.public_subnets_ids[0]

  backup_function_name          = var.backup_function_name
  backup_function_schedule_time = var.backup_function_schedule_time
  restore_function_name         = var.restore_function_name
  query_function_name           = var.query_function_name

  notifications_slack_webhook_url = var.notifications_slack_webhook_url

  depends_on = [
    module.development_cluster
  ]
}
