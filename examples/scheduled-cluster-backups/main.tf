# ------------------------------------------------------------------------------------------------------------------
# DEPLOY A LAMBDA FUNCTION THAT TAKES REGULAR SNAPSHOTS OF AN AWS ELASTICSEARCH DOMAIN
# This example shows how to use the elasticsearch-cluster-backup module to deploy
# a lambda function that takes regular snapshots of an AWS elasticsearch domain.
# ------------------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been developed with 0.13 syntax, which means it is not compatible with any versions below 0.13.
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
# DEPLOY ELASTICSEARCH CLUSTER BACKUP LAMBDA FUNCTION
# ------------------------------------------------------------------------------------------------------------------

module "elasticsearch_cluster_backup" {
  source = "../../modules/elasticsearch-cluster-backup"

  name                  = var.name
  elasticsearch_domain  = var.elasticsearch_domain
  elasticsearch_indices = var.elasticsearch_indices
  bucket                = var.bucket
  region                = var.region
  schedule_time         = var.schedule_time
  tags                  = var.tags
}
