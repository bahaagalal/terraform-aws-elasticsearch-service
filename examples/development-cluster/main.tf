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
# DEPLOY AN EC2 INSTANCE TO ACT AS A BASTION HOST TO ACCESS ELASTICSEARCH
# ------------------------------------------------------------------------------------------------------------------

resource "aws_key_pair" "bastion_instance_key" {
  key_name   = "${var.name}-pilot-key"
  public_key = file("${path.module}/${var.bastion_instance_publickey_filename}")

  tags = {
    Name = var.name
  }
}

resource "aws_security_group" "bastion_instance_security_group" {
  name        = "${var.name}-bastion-instance"
  description = "The security group for ${var.name} bastion instance."

  vpc_id = module.vpc.vpc_id

  # allow all outbound calls from the mongoshell instance
  egress {
    description = "allow all outbound communications from the bastion instance to the internet."

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow ssh connections into the bastion instance
  ingress {
    description = "allow ssh into the bastion instance."

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.name
  }
}

data "aws_ami" "amazon_linux_2" {
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

resource "aws_instance" "bastion_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.bastion_instance_type

  availability_zone = var.availability_zones[0]
  subnet_id         = module.vpc.public_subnets_ids[0]

  vpc_security_group_ids      = [aws_security_group.bastion_instance_security_group.id]
  key_name                    = aws_key_pair.bastion_instance_key.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 10
    delete_on_termination = true
  }

  tags = {
    Name = var.name
  }

  volume_tags = {
    Name = var.name
  }
}

# ------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP RULE TO ALLOW ACCESS ON THE ELASTICSEARCH CLUSTER FROM THE BASTION INSTANCE
# ------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "allow_bastion_to_cluster_communication_https" {
  type              = "ingress"
  security_group_id = module.development_cluster.security_group
  description       = "allow communication on https port from the bastion instance to the cluster."

  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_instance_security_group.id
}

resource "aws_security_group_rule" "allow_bastion_to_cluster_communication_http" {
  type              = "ingress"
  security_group_id = module.development_cluster.security_group
  description       = "allow communication on http port from the bastion instance to the cluster."

  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_instance_security_group.id
}
