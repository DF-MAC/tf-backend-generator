# Define the Terraform block where you specify the required Terraform version and provider configurations.
terraform {
  # Specify the required Terraform version for this configuration. 
  # The caret (^) symbol and version number "1.7.0" means that Terraform will use the latest version that is compatible with 1.7.0 according to semantic versioning.
  required_version = ">1.7.0"

  # Define the required providers for this Terraform configuration.
  required_providers {
    # Specify the AWS provider as a required provider.
    aws = {
      source  = "hashicorp/aws" # Indicate that the AWS provider should be sourced from the official HashiCorp Terraform registry.
      version = "~> 5.38.0"     # Specify the minimum provider version to use. Here, it means any version 5.38.0 or newer.

      configuration_aliases = [aws.replica]
    }
  }
}

# Outside the terraform block, we define provider-specific configurations, including aliases for different operational scenarios.
# Here, we define the default AWS provider configuration. This is the primary configuration that will be used unless an alias is specified for a particular resource.
provider "aws" {
  # Example primary provider configuration:
  region  = var.default_region
  profile = var.default_profile
}

provider "aws" {
  # The 'alias' attribute creates an alternative configuration named "replica". 
  # This alias allows you to manage resources in a different region or account, serving specific purposes like replication or secondary resources.
  # Note: Each aliased provider needs its unique configuration block if you're going to use it.
  alias = "replica"
  # Example secondary provider configuration:
  region  = var.replica_region
  profile = var.default_profile
  # Assume the role in the secondary account
  # assume_role {
  #   role_arn = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
  # }
  # TODO: Check on STS Assume role as a potentially more secure alternative to using the profile attribute.
}

# Note on provider aliases:
# - The default (unaliased) provider configuration is used if no alias is specified for a resource.
# - To use an aliased provider, you specify the 'provider' argument within a resource block, referencing the aliased provider like 'aws.replica'.
# - This approach allows for complex deployment patterns, such as deploying resources across multiple regions or AWS accounts from a single Terraform plan.

# Example of using the aliased provider in a resource:
# resource "aws_some_resource" "replica_resource" {
#   provider = aws.replica
#   # Configuration for the resource...
# }

# Replace the placeholder comments with actual configuration parameters as needed for your deployment scenario.
