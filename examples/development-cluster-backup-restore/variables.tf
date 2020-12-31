# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the elasticsearch cluster."
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket to upload and restore snapshots from."
  type        = string
}

variable "skip_creating_bucket" {
  description = "Determine whether the S3 bucket should be created or not. If true is specified, we assume the S3 bucket exist. If false is specified, an S3 bucket is created."
  type        = bool
}

variable "elasticsearch_bastion_instance_name" {
  description = "The name that should be assigned to the elasticsearch bastion instance."
  type        = string
}

variable "elasticsearch_bastion_instance_public_key" {
  description = "The public key to be used to ssh into the elasticsearch bastion instance."
  type        = string
}

variable "backup_function_name" {
  description = "The name that should be assigned to the lambda function responsible for triggering the backup operation."
  type        = string
}

variable "restore_function_name" {
  description = "The name that should be assigned to the lambda function responsible for triggering the restore operation."
  type        = string
}

variable "query_function_name" {
  description = "The name that should be assigned to the lambda function responsible for calling the snapshot query API."
  type        = string
}

variable "notifications_slack_webhook_url" {
  description = "The Slack webhook url to push backup notifications to."
  type        = string
}

# ------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------------------------

variable "region" {
  description = "The region that nodes in the cluster should be created in."
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "A list of availability zones that nodes in the cluster can be created in."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "11.11.11.0/24"
}

variable "public_subnets" {
  description = "A list of public subnets CIDR blocks to be created in the VPC."
  type        = list(string)
  default     = ["11.11.11.0/28", "11.11.11.16/28", "11.11.11.32/28"]
}

variable "private_subnets" {
  description = "A list of private subnets CIDR blocks to be created in the VPC."
  type        = list(string)
  default     = ["11.11.11.48/28", "11.11.11.64/28", "11.11.11.80/28"]
}

variable "elasticsearch_version" {
  description = "The version of Elasticsearch to deploy."
  type        = string
  default     = "1.5"
}

variable "data_nodes_instance_type" {
  description = "The instance type of data nodes in the cluster."
  type        = string
  default     = "m4.large.elasticsearch"
}

variable "data_nodes_instance_count" {
  description = "The number of data nodes in the cluster."
  type        = number
  default     = 3
}

variable "skip_creating_service_linked_role" {
  description = "Determine whether the Elasticsearch service linked role should be created. Only one service linked role is required per AWS account. If true is specified, we assume the service linked role exists. If false is specified, a service linked role is created."
  type        = bool
  default     = true
}

variable "elasticsearch_bastion_instance_type" {
  description = "The type of EC2 instance to launch for elasticsearch bastion instance."
  type        = string
  default     = "t3.small"
}

variable "backup_function_schedule_time" {
  description = "A cloudwatch schedule expression or valid cron expression to specify how often the backup function should run."
  type        = string
  default     = "rate(60 minutes)"
}
