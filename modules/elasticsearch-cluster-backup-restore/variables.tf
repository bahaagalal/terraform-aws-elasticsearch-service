# ------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------------------------

variable "bucket_name" {
  description = "The name of the S3 bucket to upload and restore snapshots from."
  type        = string
}

variable "bucket_region" {
  description = "The region of the S3 bucket."
  type        = string
}

variable "elasticsearch_domain_name" {
  description = "The name of the Elasticsearch domain to take and restore snapshots from."
  type        = string
}

variable "elasticsearch_domain_security_group" {
  description = "The ID of the Elasticsearch domain security group."
  type        = string
}

variable "elasticsearch_bastion_instance_name" {
  description = "The name that should be assigned to the elasticsearch bastion instance."
  type        = string
}

variable "elasticsearch_bastion_instance_public_key" {
  description = "The public key to be used to ssh into the elasticsearch bastion instance."
  type        = string
}

variable "elasticsearch_bastion_instance_availability_zone" {
  description = "The AWS availability zone to launch the elasticsearch bastion instance in."
  type        = string
}

variable "elasticsearch_bastion_instance_vpc" {
  description = "The ID of the VPC to launch the elasticsearch bastion instance in."
  type        = string
}

variable "elasticsearch_bastion_instance_subnet" {
  description = "The ID of the subnet to launch the elasticsearch bastion instance in."
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

variable "skip_creating_bucket" {
  description = "Determine whether the S3 bucket should be created or not. If true is specified, we assume the S3 bucket exist. If false is specified, an S3 bucket is created."
  type        = bool
  default     = false
}

variable "elasticsearch_bastion_instance_ssh_port" {
  description = "The port on which the elasticsearch bastion instance accepts ssh connections."
  type        = number
  default     = 22
}

variable "elasticsearch_bastion_instance_ssh_cidr_blocks" {
  description = "The list of CIDR blocks that can ssh into the elasticsearch bastion instance."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "elasticsearch_bastion_instance_type" {
  description = "The type of EC2 instance to launch for elasticsearch bastion instance."
  type        = string
  default     = "t3.small"
}

variable "elasticsearch_bastion_instance_root_volume_size" {
  description = "The size in gigabytes of the root volume of the elasticsearch bastion instance."
  type        = number
  default     = 10
}

variable "backup_function_memory_size" {
  description = "The amount of memory in megabytes that the backup lambda function can use in runtime."
  type        = number
  default     = 128
}

variable "backup_function_timeout" {
  description = "The amount of time in seconds that the backup lambda function has to run before it times out."
  type        = number
  default     = 900
}

variable "backup_function_schedule_time" {
  description = "A cloudwatch schedule expression or valid cron expression to specify how often the backup function should run."
  type        = string
  default     = "rate(24 hours)"
}

variable "skip_scheduling_backup_function" {
  description = "Determines whether the scheduled cloudwatch event of the backup lambda function should be enabled by default or not. If true is specified, the backup lambda function will not be scheduled. If false is specified, the backup lambda function will be scheduled."
  type        = bool
  default     = false
}

variable "restore_function_memory_size" {
  description = "The amount of memory in megabytes that the restore lambda function can use in runtime."
  type        = number
  default     = 128
}

variable "restore_function_timeout" {
  description = "The amount of time in seconds that the restore lambda function has to run before it times out."
  type        = number
  default     = 900
}

variable "query_function_memory_size" {
  description = "The amount of memory in megabytes that the query lambda function can use in runtime."
  type        = number
  default     = 128
}

variable "query_function_timeout" {
  description = "The amount of time in seconds that the query lambda function has to run before it times out."
  type        = number
  default     = 900
}

variable "tags" {
  description = "A map of tags to assign to the resources created by this module."
  type        = map(string)
  default     = {}
}
