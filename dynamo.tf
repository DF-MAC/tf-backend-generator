# Define local variables for ease of use and clarity within the configuration
locals {
  # Define the primary key name for the DynamoDB table, which is required for Terraform state locking
  lock_key_id = "LockID"
}

# Define a DynamoDB table resource for locking Terraform state operations
resource "aws_dynamodb_table" "lock" {
  # Set the table name from a variable, allowing customization
  name = var.dynamodb_table_name
  # Configure the billing mode of the table (e.g., PROVISIONED or PAY_PER_REQUEST)
  billing_mode = var.dynamodb_table_billing_mode
  # Use the local variable as the hash key for the table
  hash_key = local.lock_key_id
  # Enable or disable deletion protection based on a variable
  deletion_protection_enabled = var.dynamodb_deletion_protection_enabled

  # Define an attribute for the table, which is the primary key with a String type
  attribute {
    name = local.lock_key_id
    type = "S"
  }

  # Configure server-side encryption using a specified KMS key
  server_side_encryption {
    enabled     = var.dynamodb_enable_server_side_encryption
    kms_key_arn = aws_kms_key.this.arn
  }

  # Enable point-in-time recovery to allow for restoration of the table to a specific time
  point_in_time_recovery {
    enabled = true
  }

  # Conditional creation of DynamoDB table replicas for cross-region replication
  dynamic "replica" {
    # Create a replica if replication is enabled
    for_each = var.enable_replication == true ? [1] : []
    content {
      # Set the region for the replica based on a data source
      region_name = data.aws_region.replica[0].name
      # Conditionally set the KMS key ARN for the replica's encryption
      kms_key_arn = var.dynamodb_enable_server_side_encryption ? aws_kms_key.replica[0].arn : null
    }
  }
  # Enable DynamoDB Streams if replication is enabled, required for table replication
  stream_enabled = var.enable_replication
  # Set the stream view type, which determines the information stored in the stream records
  stream_view_type = var.enable_replication ? "NEW_AND_OLD_IMAGES" : null

  # Apply tags to the DynamoDB table resource from a variable
  tags = var.tags
}
