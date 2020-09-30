# Scheduled Cluster Backups Example

This folder contains a Terraform example for deploying a *lambda* function that takes regular elasticsearch cluster backups for an AWS Elasticsearch Domain.

The end result of this example is a lambda function, an S3 bucket, and a cloudwatch trigger.

## Quick Start

To deploy:

1. Modify `main.tf` to customize your AWS region.
2. Modify `variables.tf` to customize the lambda function name, the elasticsearch domain endpoint, the s3 bucket name & region, and the schedule time.
3. Run `terraform init`.
4. Run `terraform apply`.
5. Validate that the s3 repository is registered in Elasticsearch and that snapshots are being taken.
