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

variable "elasticsearch_domain" {
  description = "The name for the elasticsearch domain."
  type        = string
}

variable "elasticsearch_indices" {
  description = "A list of elasticsearch indices to take snapshots for."
  type        = list(string)
}

# ------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name for the lambda function."
  type        = string
  default     = "night-king"
}

variable "bucket" {
  description = "The name of the S3 bucket to store snapshots to."
  type        = string
  default     = "night-king.elasticsearch.backups"
}

variable "region" {
  description = "The region where the s3 bucket exists."
  type        = string
  default     = "us-east-1"
}

variable "schedule_time" {
  description = "A cloudWatch schedule expression or valid cron expression to specify how often a backup should be done."
  type        = string
  default     = "rate(5 minutes)"
}

variable "tags" {
  description = "A map of tags to assign to the resources created by this module."
  type        = map(string)
  default     = {}
}
