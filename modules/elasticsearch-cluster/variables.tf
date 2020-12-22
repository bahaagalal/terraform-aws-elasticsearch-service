# ------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the elasticsearch cluster."
  type        = string
}

variable "elasticsearch_version" {
  description = "The version of Elasticsearch to deploy."
  type        = string
}

variable "vpc_id" {
  description = "The VPC that nodes in the cluster should be created in."
  type        = string
}

variable "availability_zones" {
  description = "A list of availability zones that nodes in the cluster can be created in."
  type        = list(string)
}

variable "subnet_ids" {
  description = "A list of VPC Subnet IDs for the Elasticsearch domain endpoints to be created in."
  type        = list(string)
}

variable "data_nodes_instance_type" {
  description = "The instance type of data nodes in the cluster."
  type        = string
}

# ------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------------------------

variable "additional_security_group_ids" {
  description = "A list of additional VPC Security Group IDs to be applied to the Elasticsearch domain endpoints."
  type        = list(string)
  default     = []
}

variable "skip_creating_service_linked_role" {
  description = "Determine whether the Elasticsearch service linked role should be created. Only one service linked role is required per AWS account. If true is specified, we assume the service linked role exists. If false is specified, a service linked role is created."
  type        = bool
  default     = false
}

variable "master_nodes_instance_type" {
  description = "The instance type of the dedicated master nodes in the cluster."
  type        = string
  default     = null
}

variable "master_nodes_instance_count" {
  description = "The number of dedicated master nodes in the cluster."
  type        = number
  default     = 0
}

variable "data_nodes_instance_count" {
  description = "The number of data nodes in the cluster."
  type        = number
  default     = 3
}

variable "data_nodes_volume_size" {
  description = "The size of EBS volumes attached to data nodes in GiB."
  type        = number
  default     = 20
}

variable "warm_nodes_instance_type" {
  description = "The instance type for the Elasticsearch cluster's warm nodes."
  type        = string
  default     = null
}

variable "warm_nodes_instance_count" {
  description = "The number of warm nodes in the cluster."
  type        = number
  default     = 0
}

variable "enforce_https" {
  description = "Whether or not to require HTTPS."
  type        = bool
  default     = false
}

variable "snapshot_hour" {
  description = "The hour during which the service takes an automated daily snapshot of the indices in the domain."
  type        = number
  default     = 22
}

variable "fielddata_cache" {
  description = "The percentage of Java heap space that is allocated to field data."
  type        = number
  default     = 40
}

variable "tags" {
  description = "A map of tags to assign to the cluster."
  type        = map(string)
  default     = {}
}
