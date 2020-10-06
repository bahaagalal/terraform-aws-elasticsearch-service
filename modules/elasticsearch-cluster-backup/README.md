# Elasticsearch Cluster Backup Module

This terraform module takes snapshots of an Elasticsearch cluster to an S3 bucket. The module is a scheduled lambda function that calls the elasticsearch APIs to perform snapshotting and backup related tasks documented [here](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html). It also deploys another lambda function that allows you to query the snapshot API on demand.

---

## Terminologies

- **Repository**: A repository is an elasticsearch abstraction over a storage medium like a *shared file system*, *s3 bucket*, HDFS etc. It is used to identify where snapshot files are stored.

- **Snapshot**: A snapshot represents the current state of the indices in an Elasticsearch cluster.

---

## How do you use this module?

The module works by deploying an AWS Lambda function that performs backups on a configurable schedule. This module saves all snapshots to S3.

```tf
module "elasticsearch_cluster_backup" {
  # Use version v1.0.0 of the elasticsearch-cluster-backup module
  source = "git::git@github.com/crowdanalyzer/terraform-aws-elasticsearch-service//modules/elasticsearch-cluster-backup?ref=v1.0.0"

  name                   = "..."
  elasticsearch_domain   = "..."
  bucket                 = "..."
  region                 = "..."
  schedule_time         = "..."
}
```

Note the following parameters:

- `source`: Use this parameter to specify the URL of this module. The double slash `//` is intentional and required. Terraform uses it to specify subfolders within a Git repo. The `ref` parameter specifies a specific Git tag in this repo. That way, instead of using the latest version of this module from the master branch, which will change every time you run Terraform, you're using a fixed version of the repo.

- `name`: The name that should be assigned to the lambda function.

- `elasticsearch_domain`: The name of the elasticsearch domain.

- `bucket`: The S3 bucket where snapshots will be stored. Set `bucket_exists` parameter to `true` if bucket exists and doesn't need to be created.

- `region`: The region where the s3 bucket exists.

- `schedule_time`: A cloudWatch schedule expression or valid cron expression to specify how often a backup should be done. (e.g. `cron(0 20 * * ? *)`, `rate(5 minutes)`).

You can find the other parameters in [variables.tf](./variables.tf). Check out the [examples](../../examples) folder for working sample code.

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

### References

1. [Elasticsearch Managed Domains Snapshots](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains-snapshots.html)
2. [Kinesis Lambda Elasticsearch Sample Code](https://github.com/aws-samples/amazon-elasticsearch-lambda-samples/blob/master/src/kinesis_lambda_es.js)
3. [AWS Lambda Scheduled Events](https://www.thedevcoach.co.uk/terraform-lambda-scheduled-event/).
