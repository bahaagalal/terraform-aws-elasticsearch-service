# Elasticsearch Service Modules

![CircleCI](https://circleci.com/gh/crowdanalyzer/terraform-aws-elasticsearch-service.svg?style=shield&circle-token=ee4c42aecefaa755b1adadd17910023bb89d9a4d)

This repo contains several modules for creating and managing Amazon Elasticsearch Cluster.

---

## Supporting Modules

This repo contain several supporting modules that add extra functionality on top of the main module:

- **[elasticsearch-cluster-backup](./modules/elasticsearch-cluster-backup/)**: Creates a scheduled lambda function that calls the Elasticsearch API to perform snapshotting and backup related tasks documented [here](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html).

---

## How do you use a module?

To use a module in your Terraform templates, create a `module` resource and sets its `source` field to the Git url of this repo. You should also set the `ref` parameter so you are fixed to a specific version of this repo, for example to use `v1.0.0` of the `elasticsearch-cluster-backup` module, you should add the following:

```tf
module "elasticsearch_cluster_backup" {
    source = "git::git@github.com:crowdanalyzer/terraform-aws-elasticsearch-service//modules/elasticsearch-cluster-backup?ref=v1.0.0"

    # set the parameters for the elasticsearch-cluster-backup module
}
```

**Note**: the double slash `//` is intentional and required. It is part of Terraform's Git syntax. See the module documentation and `variables.tf` file for all the parameters you can set. Run `terraform init` to pull the latest version of this module from this repo before running the standard `terraform apply` command.

---
