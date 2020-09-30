# ------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the lambda function."
  type        = string
}

variable "elasticsearch_domain" {
  description = "The name of the elasticsearch domain."
  type        = string
}

variable "bucket" {
  description = "The S3 bucket where snapshots will be stored."
  type        = string
}

variable "region" {
  description = "The region where the s3 bucket exists."
  type        = string
}

variable "schedule_time" {
  description = "A cloudWatch schedule expression or valid cron expression to specify how often a backup should be done."
  type        = string
}

# ------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------------------------

variable "bucket_exists" {
  description = "Whether the S3 bucket should be created or not."
  type        = bool
  default     = false
}

variable "lambda_memory_size" {
  description = "The amount of memory in MB the lambda function can use in runtime."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "The amount of time the Lambda Function has to run in seconds."
  type        = number
  default     = 300
}

variable "elasticsearch_indices" {
  description = "A list of elasticsearch indices to take snapshots for."
  type        = list(string)
  default     = ["*"]
}

variable "enable_lambda_scheduled_event" {
  description = "Whether the lambda scheduled cloudwatch event rule should be enabled by default or not."
  type        = bool
  default     = true
}

variable "tags" {
  description = "The tags that should be associated with the resources created by this module."
  type        = map(string)
  default     = {}
}
