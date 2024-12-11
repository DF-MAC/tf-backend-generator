#!/bin/bash

# Initialize Terraform (assumes you're in the directory with your Terraform configuration)
terraform init || { echo "Error: Terraform initialization failed, please check your configuration" ; exit 1; }

terraform fmt -recursive

# terraform validate with error handling
terraform validate || { echo "Error: Terraform validation failed, please check your configuration" ; exit 1; }

# Apply Terraform configuration to create the resources
terraform apply -auto-approve

echo "state_bucket: $(terraform output -json state_bucket)"
echo "dynamodb_table: $(terraform output -json dynamodb_table)"
echo "kms_key: $(terraform output -json kms_key)"


# Capture outputs of state_bucket.arn, dynamodb_table.name, and kms_key_alias.arn

S3_BUCKET=$(terraform output -json state_bucket | jq -r .bucket)
S3_BUCKET_REGION=$(terraform output -json state_bucket | jq -r .region)
DYNAMODB_TABLE=$(terraform output -json dynamodb_table | jq -r .id)
KMS_KEY_ID=$(terraform output -json kms_key | jq -r .id)

# Generate backend configuration
cat <<EOF >backend.tf
terraform {
  backend "s3" {
    bucket         = "$S3_BUCKET"
    key            = "state/key/path/terraform.tfstate"
    region         = "$S3_BUCKET_REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
    kms_key_id     = "$KMS_KEY_ID"
  }
}
EOF

echo "Backend configuration generated in backend.tf"
