# Development Cluster with Backup and Restore Functionality Example

This folder contains an example of how to use the **[elasticsearch-cluster-backup-restore module](../../modules/elasticsearch-cluster-backup-restore)** to create an Elasticsearch cluster using AWS Elasticsearch service with backup and restore operations enabled.

---

## How do you run this example?

To run this example, you need to:
1. Install **[terraform](https://www.terraform.io)**.
2. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in the file that don't have defaults.
3. Run `terraform init`.
4. Run `terraform apply`.
5. Validate by executing *restore*, *backup*, and *query* lambda functions:
```js
// restore event
{
  "snapshot": "<SNAPSHOT_NAME>",
  "indices": "*",
  "include_aliases": false,
  "include_global_state": false
}

// backup event
{
  "indices": [
    "<INDEX_ONE>",
    "<INDEX_TWO>"
  ],
  "include_global_state": true
}

// query event
{
  "snapshot": "<SNAPSHOT_NAME>"
}
```
