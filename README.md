# Elasticsearch Service Modules

![CircleCI](https://circleci.com/gh/crowdanalyzer/terraform-aws-elasticsearch-service.svg?style=shield&circle-token=ee4c42aecefaa755b1adadd17910023bb89d9a4d)

This repo contains several modules for creating and managing [Amazon Elasticsearch Cluster](https://aws.amazon.com/elasticsearch-service/).

---

## Main Modules

The main module of this repo is

- **[elasticsearch-cluster](./modules/elasticsearch-cluster)**: Creates an Elasticsearch cluster. This cluster is managed by AWS and automatically detects and replaces failed nodes.

---

## Supporting Modules

This repo contain several supporting modules that add extra functionality on top of the `elasticsearch-cluster` module:

- **[elasticsearch-cluster-backup-restore](./modules/elasticsearch-cluster-backup-restore/)**: Creates two lambda functions; a scheduled lambda function that calls the Elasticsearch API to perform snapshotting and backup related tasks, and a second lambda function that calls the Elasticsearch API to perform restore related tasks.

---

## How do you use a module?

To use a module in your terraform templates, create a `module` resource and sets its `source` field to the git url of this repo. You should also set the `ref` parameter so you are fixed to a specific version of this repo, for example to use `v1.1.0` of the `elasticsearch-cluster` module, you should add the following:

```tf
module "elasticsearch_cluster" {
  source = "git::git@github.com:crowdanalyzer/terraform-aws-elasticsearch-service//modules/elasticsearch-cluster?ref=v1.1.0"

  # set the parameters for the elasticsearch-cluster module
}
```

**Note**: the double slash `//` is intentional and required. It is part of terraform's git syntax. See the module documentation and `variables.tf` file for all the parameters you can set. Run `terraform init` to pull the latest version of this module from this repo before running the standard `terraform apply` command.
