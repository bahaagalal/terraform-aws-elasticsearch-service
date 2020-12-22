# Elasticsearch Cluster Module

This module creates an **Elasticsearch** cluster. The Elasticsearch cluster is managed by AWS and automatically detects and replaces failed nodes, streamlines software upgrades and patches, enables easy scaling of the cluster both horizontally (add more nodes) and vertically (increase the computational power and memory of existing nodes), and simplifies backup and restore functionality.

---

## How do you use this module?

This module works by deploying an **AWS Elasticsearch Service Domain**.

You can use this module in your code by adding a `module` resource and setting its `source` parameter to the `URL` of this folder:

```hcl
module "elasticsearch_cluster" {
  # Use version v1.1.0 of the elasticsearch-cluster module
  source = "git::git@github.com:crowdanalyzer/terraform-aws-elasticsearch-service//modules/elasticsearch-cluster?ref=v1.1.0"

  name = "..."

  elasticsearch_version = "..."

  vpc_id                            = "..."
  availability_zones                = "..."
  subnet_ids                        = "..."
  additional_security_group_ids     = "..."
  skip_creating_service_linked_role = "..."

  master_nodes_instance_type  = "..."
  master_nodes_instance_count = "..."

  data_nodes_instance_type  = "..."
  data_nodes_instance_count = "..."
  data_nodes_volume_size    = "..."

  warm_nodes_instance_type  = "..."
  warm_nodes_instance_count = "..."

  enforce_https = "..."

  snapshot_hour = "..."

  fielddata_cache = "..."

  tags = "..."
}
```

Note the following parameters:

- `source`: Use this parameter to specify the URL of this module. The double slash `//` is intentional and required. Terraform uses it to specify subfolders within a git repo. The `ref` parameter specifies a specific git tag in this repo. That way, instead of using the latest version of this module from the master branch, which will change every time you run Terraform, you're using a fixed version of the repo.

- `name`: The name of the elasticsearch cluster.

- `elasticsearch_version`: The version of Elasticsearch to deploy.

- `vpc_id`: The VPC that nodes in the cluster should be created in.

- `availability_zones`: A list of availability zones that nodes in the cluster can be created in.

- `subnet_ids`: A list of VPC Subnet IDs for the Elasticsearch domain endpoints to be created in.

- `additional_security_group_ids`: A list of additional VPC Security Group IDs to be applied to the Elasticsearch domain endpoints. Default `[]`.

- `skip_creating_service_linked_role`: Determine whether the Elasticsearch service linked role should be created. Only one service linked role is required per AWS account. If true is specified, we assume the service linked role exists. If false is specified, a service linked role is created. Default `false`.

- `master_nodes_instance_type`: The instance type of the dedicated master nodes in the cluster. Default `null`.

- `master_nodes_instance_count`: The number of dedicated master nodes in the cluster. Default `0`.

- `data_nodes_instance_type`: The instance type of data nodes in the cluster.

- `data_nodes_instance_count`: The number of data nodes in the cluster. Default `3`.

- `data_nodes_volume_size`: The size of EBS volumes attached to data nodes in GiB. Default `20`.

- `warm_nodes_instance_type`: The instance type for the Elasticsearch cluster's warm nodes. Default `null`.

- `warm_nodes_instance_count`: The number of warm nodes in the cluster. Default `0`.

- `enforce_https`: Whether or not to require HTTPS. Default `false`.

- `snapshot_hour`: The hour during which the service takes an automated daily snapshot of the indices in the domain. Default `22`.

- `fielddata_cache`: The percentage of Java heap space that is allocated to field data. Default `40`.

- `tags`: A map of tags to assign to the cluster. Default `{}`.

You can find the other parameters in [variables.tf](./variables.tf). Check out the [examples](../../examples) folder for working sample code.
