# ------------------------------------------------------------------------------------------------------------------
# REQUIRE SPECIFIC TERRAFORM VERSION
# This module has been developed with 0.13 syntax, which means it is not compatible with any versions below 0.13.
# ------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.13, < 0.14"

  required_providers {
    # REQUIRE SPECIFIC AWS PROVIDER VERSION
    # This module has been developed with AWS provider version 3.3.0, which means it is not compatible with any version below 3.3.0
    aws = {
      version = ">= 3.3.0, < 4.0.0"
    }
  }
}
