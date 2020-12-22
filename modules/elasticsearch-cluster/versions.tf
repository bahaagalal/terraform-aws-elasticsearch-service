# ------------------------------------------------------------------------------------------------------------------
# REQUIRE SPECIFIC TERRAFORM VERSION
# This module has been developed with 0.13 syntax, which means it is not compatible with any versions below 0.13.
# ------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.13, < 0.14"

  # ------------------------------------------------------------------------------------------------------------------
  # REQUIRE SPECIFIC AWS PROVIDER VERSION
  # This module has been developed with AWS provider version 3.14.0, which means it is not compatible with any version below 3.14.0
  # ------------------------------------------------------------------------------------------------------------------
  required_providers {
    aws = {
      version = ">= 3.14.0, < 4.0.0"
    }
  }
}
