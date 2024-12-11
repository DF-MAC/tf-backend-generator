# Determine the need for a replication IAM role based on the provided conditions.
locals {
  replication_role_count = var.iam_role_arn == null && var.enable_replication ? 1 : 0
}

# Fetch the AWS region information for the replication target if replication is enabled.
data "aws_region" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica
}

# Create a KMS key for encrypting the replicated S3 bucket if replication is enabled.
resource "aws_kms_key" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  description             = var.kms_key_description
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_key_rotation

  tags = var.tags
}

# Define an IAM role for bucket replication with a predefined assume role policy that allows S3 service to assume this role.
# TODO: Create inline policy JSON at "assume_role_policy" attribute
resource "aws_iam_role" "replication" {
  count = local.replication_role_count

  name_prefix = var.override_iam_role_name ? null : var.iam_role_name_prefix
  name        = var.override_iam_role_name ? var.iam_role_name : null
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "s3.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })


  permissions_boundary = var.iam_role_permissions_boundary
  tags                 = var.tags
}

# Create an IAM policy for the replication role, defining the permissions necessary for the replication process.
#TODO: Create inline policy JSON at "policy" attribute
resource "aws_iam_policy" "replication" {
  count = local.replication_role_count

  name_prefix = var.override_iam_policy_name ? null : var.iam_policy_name_prefix
  name        = var.override_iam_policy_name ? var.iam_policy_name : null
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::source-bucket/*",
          "arn:aws:s3:::source-bucket"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach the defined IAM policy to the replication role.
resource "aws_iam_policy_attachment" "replication" {
  count = local.replication_role_count

  name       = var.iam_policy_attachment_name
  roles      = [aws_iam_role.replication[0].name]
  policy_arn = aws_iam_policy.replication[0].arn
}

# Define a policy document to enforce SSL for S3 bucket access if replication is enabled.
data "aws_iam_policy_document" "replica_force_ssl" {
  count = var.enable_replication ? 1 : 0

  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.replica[0].arn,
      "${aws_s3_bucket.replica[0].arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# Create the S3 bucket for the replica if replication is enabled.
resource "aws_s3_bucket" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket_prefix = var.override_s3_bucket_name ? null : var.replica_bucket_prefix
  bucket        = var.override_s3_bucket_name ? var.s3_bucket_name_replica : null
  force_destroy = var.s3_bucket_force_destroy

  tags = var.tags
}

# Set ownership controls for the replica S3 bucket.
resource "aws_s3_bucket_ownership_controls" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.replica[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Apply an ACL to the replica S3 bucket to make it private.
resource "aws_s3_bucket_acl" "replica" {
  depends_on = [aws_s3_bucket_ownership_controls.replica]
  count      = var.enable_replication ? 1 : 0
  provider   = aws.replica

  bucket = aws_s3_bucket.replica[0].id
  acl    = "private"
}

# Enable versioning on the replica S3 bucket.
resource "aws_s3_bucket_versioning" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.replica[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configure server-side encryption for the replica S3 bucket using the previously created KMS key.
resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.replica[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.replica[0].arn
    }
  }
}

# Attach the policy document enforcing SSL to the replica S3 bucket.
resource "aws_s3_bucket_policy" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.replica[0].id
  policy = data.aws_iam_policy_document.replica_force_ssl[0].json
}
