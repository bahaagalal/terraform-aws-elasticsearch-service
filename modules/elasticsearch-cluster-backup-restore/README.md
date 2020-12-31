# Elasticsearch Cluster Back Up and Restore Module

This directory contains a Terraform module to take and restore snapshots of an **Amazon Elasticsearch Service** cluster from an S3 bucket.

The module works by deploying **two lambda functions** that call the elasticsearch APIs to perform *snapshotting* related tasks documented [here](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html). It deploys a **third lambda function** that allows you to *query* the *snapshot API*. Finally, it deploys an **EC2 instance** with `curl` command so you can easily run arbitrary API calls against the cluster.

---

## Terminologies

- **Repository**: A repository is an elasticsearch abstraction over a storage medium like a *shared file system*, *s3 bucket*, HDFS etc. It is used to identify where snapshot files are stored.

- **Snapshot**: A snapshot represents the current state of the indices in an Elasticsearch cluster.

---

## Taking Backups

Cluster snapshots are incremental. The first snapshot is always a full dump of the cluster and subsequent ones are a delta between the current state of the cluster and the previous snapshot. Snapshots are typically contained in .dat files stored in the storage medium (in this case S3) the repository points to.

---

## CPU and Memory Usage

Snapshots are usually run on a single node which automatically coordinates with other nodes to ensure completness of data. Backup of a cluster with a large volume of data will lead to high CPU and memory usage on the node performing the backup. This module makes backup requests to the cluster through the load balancer which routes the request to one of the nodes, during backup, if the selected node is unable to handle incoming requests the load balancer will direct the request to other nodes.

---

## Frequency of Backups

How often you make backups depends entirely on the size of your deployment and the importance of your data. Larger clusters with high volume usage will typically need to be backed up more frequently than low volume clusters because of the amount of data change between snapshots. It's a safe bet to start off running backups on a nightly schedule and then continually tweak the schedule based on the demands of your cluster.

---

## How do you use this module?

The module works by deploying **three AWS Lambda functions** that calls the Elasticsearch Snapshot APIs and an **EC2 instance** with `curl` command.

```hcl
module "elasticsearch_cluster_backup_restore" {
  # Use version v2.0.0 of the elasticsearch-cluster-backup-restore module
  source = "git::git@github.com:crowdanalyzer/terraform-aws-elasticsearch-service//modules/elasticsearch-cluster-backup-restore?ref=v2.0.0"

  bucket_name           = "..."
  bucket_region         = "..."
  skip_creating_bucket  = "..."

  elasticsearch_domain_name            = "..."
  elasticsearch_domain_security_group  = "..."

  elasticsearch_bastion_instance_name              = "..."
  elasticsearch_bastion_instance_public_key        = "..."
  elasticsearch_bastion_instance_ssh_port          = "..."
  elasticsearch_bastion_instance_ssh_cidr_blocks   = "..."
  elasticsearch_bastion_instance_availability_zone = "..."
  elasticsearch_bastion_instance_vpc               = "..."
  elasticsearch_bastion_instance_subnet            = "..."
  elasticsearch_bastion_instance_type              = "..."
  elasticsearch_bastion_instance_root_volume_size  = "..."

  backup_function_name            = "..."
  backup_function_memory_size     = "..."
  backup_function_timeout         = "..."
  backup_function_schedule_time   = "..."
  skip_scheduling_backup_function = "..."

  restore_function_name          = "..."
  restore_function_memory_size   = "..."
  restore_function_timeout       = "..."

  query_function_name          = "..."
  query_function_memory_size   = "..."
  query_function_timeout       = "..."

  notifications_slack_webhook_url = "..."

  tags = "..."
}
```

Note the following parameters:

- `source`: Use this parameter to specify the URL of this module. The double slash `//` is intentional and required. Terraform uses it to specify subfolders within a git repo. The `ref` parameter specifies a specific git tag in this repo. That way, instead of using the latest version of this module from the master branch, which will change every time you run Terraform, you're using a fixed version of the repo.

- `bucket_name`: The name of the S3 bucket to upload and restore snapshots from.

- `bucket_region`: The region of the S3 bucket.

- `skip_creating_bucket`: Determine whether the S3 bucket should be created or not. If true is specified, we assume the S3 bucket exist. If false is specified, an S3 bucket is created. Default `false`.

- `elasticsearch_domain_name`: The name of the Elasticsearch domain to take and restore snapshots from.

- `elasticsearch_domain_security_group`: The ID of the Elasticsearch domain security group.

- `elasticsearch_bastion_instance_name`: The name that should be assigned to the elasticsearch bastion instance.

- `elasticsearch_bastion_instance_public_key`: The public key to be used to ssh into the elasticsearch bastion instance.

- `elasticsearch_bastion_instance_ssh_port`: The port on which the elasticsearch bastion instance accepts ssh connections. Default `22`.

- `elasticsearch_bastion_instance_ssh_cidr_blocks`: The list of CIDR blocks that can ssh into the elasticsearch bastion instance. Default `["0.0.0.0/0"]`.

- `elasticsearch_bastion_instance_availability_zone`: The AWS availability zone to launch the elasticsearch bastion instance in.

- `elasticsearch_bastion_instance_vpc`: The ID of the VPC to launch the elasticsearch bastion instance in.

- `elasticsearch_bastion_instance_subnet`: The ID of the subnet to launch the elasticsearch bastion instance in.

- `elasticsearch_bastion_instance_type`: The type of EC2 instance to launch for elasticsearch bastion instance. Default `t3.small`.

- `elasticsearch_bastion_instance_root_volume_size`: The size in gigabytes of the root volume of the elasticsearch bastion instance. Default `10`.

- `backup_function_name`: The name that should be assigned to the lambda function responsible for triggering the backup operation.

- `backup_function_memory_size`: The amount of memory in megabytes that the backup lambda function can use in runtime. Default `128`.

- `backup_function_timeout`: The amount of time in seconds that the backup lambda function has to run before it times out. Default `900`.

- `backup_function_schedule_time`: A cloudwatch schedule expression or valid cron expression to specify how often the backup function should run. Default `rate(24 hours)`.

- `skip_scheduling_backup_function`: Determines whether the scheduled cloudwatch event of the backup lambda function should be enabled by default or not. If true is specified, the backup lambda function will not be scheduled. If false is specified, the backup lambda function will be scheduled. Default `false`.

- `restore_function_name`: The name that should be assigned to the lambda function responsible for triggering the restore operation.

- `restore_function_memory_size`: The amount of memory in megabytes that the restore lambda function can use in runtime. Default `128`.

- `restore_function_timeout`: The amount of time in seconds that the restore lambda function has to run before it times out. Default `900`.

- `query_function_name`: The name that should be assigned to the lambda function responsible for calling the snapshot query API.

- `query_function_memory_size`: The amount of memory in megabytes that the query lambda function can use in runtime. Default `128`.

- `query_function_timeout`: The amount of time in seconds that the query lambda function has to run before it times out. Default `900`.

- `notifications_slack_webhook_url`: The Slack webhook url to push backup notifications to.

- `tags`: A map of tags to assign to the resources created by this module. Default `{}`.

You can find the other parameters in [variables.tf](./variables.tf). Check out the [examples](../../examples) folder for working sample code.
