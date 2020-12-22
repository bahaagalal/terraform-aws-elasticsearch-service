# Development Cluster Example

This folder contains an example of how to use the **[elasticsearch-cluster module](../../modules/elasticsearch-cluster)** to create an Elasticsearch cluster using AWS Elasticsearch service.

---

## How do you run this example?

To run this example, you need to:
1. Install **[terraform](https://www.terraform.io)**.
2. Open up `variables.tf` and set secrets at the top of the file as environment variables and fill in any other variables in the file that don't have defaults.
3. Run `terraform init`.
4. Run `terraform apply`.
5. Validate by *SSH* into the *EC2 instance* created by this example, run `curl` against the cluster endpoint.
```shell
curl -XGET <cluster_endpoint>
```
