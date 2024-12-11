# Determine if lifecycle rules should be defined based on whether noncurrent version expiration or transitions are specified.
locals {
  define_lifecycle_rule = var.noncurrent_version_expiration != null || length(var.noncurrent_version_transitions) > 0
}

# Data source to fetch the current AWS region information.
data "aws_region" "state" {
}

# KMS Key used for encrypting the S3 bucket.
resource "aws_kms_key" "this" {
  description             = var.kms_key_description
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_key_rotation
  tags                    = var.tags
}

# KMS alias for the KMS key, making it easier to manage and reference.
resource "aws_kms_alias" "this" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.this.key_id
}

# IAM policy document to enforce SSL (HTTPS) requests only for the S3 bucket.
data "aws_iam_policy_document" "state_force_ssl" {
  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*"
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

# Attaches the SSL enforcement policy to the S3 bucket.
resource "aws_s3_bucket_policy" "state_force_ssl" {
  bucket     = aws_s3_bucket.state.id
  policy     = data.aws_iam_policy_document.state_force_ssl.json
  depends_on = [aws_s3_bucket_public_access_block.state]
}

# Configuration of the S3 bucket with options for naming, destruction, and tagging.
resource "aws_s3_bucket" "state" {
  bucket_prefix = var.override_s3_bucket_name ? null : var.state_bucket_prefix
  bucket        = var.override_s3_bucket_name ? var.s3_bucket_name : null
  force_destroy = var.s3_bucket_force_destroy
  tags          = var.tags
}

# Sets the ownership control of the S3 bucket for better management of object ownership.
resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Sets the access control list (ACL) for the S3 bucket to private.
resource "aws_s3_bucket_acl" "state" {
  depends_on = [aws_s3_bucket_ownership_controls.state]
  bucket     = aws_s3_bucket.state.id
  acl        = "private"
}

# Enables versioning for the S3 bucket to keep multiple versions of an object in the same bucket.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configures logging for the S3 bucket to another S3 bucket.
#TODO: Check this out regarding the logging bucket vs. the backend bucket. 
resource "aws_s3_bucket_logging" "state" {
  count         = var.s3_logging_target_bucket != null ? 1 : 0
  bucket        = aws_s3_bucket.state.id
  target_bucket = var.s3_logging_target_bucket
  target_prefix = var.s3_logging_target_prefix
}

# Configures server-side encryption for the S3 bucket using the specified KMS key.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.this.arn
    }
  }
}

# Configures lifecycle rules for the S3 bucket, such as transitioning older versions to different storage classes or expiring them.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  count  = local.define_lifecycle_rule ? 1 : 0
  bucket = aws_s3_bucket.state.id
  rule {
    id     = "auto-archive"
    status = "Enabled"
    dynamic "noncurrent_version_transition" {
      for_each = var.noncurrent_version_transitions
      content {
        noncurrent_days = noncurrent_version_transition.value.days
        storage_class   = noncurrent_version_transition.value.storage_class
      }
    }
    dynamic "noncurrent_version_expiration" {
      for_each = var.noncurrent_version_expiration != null ? [var.noncurrent_version_expiration] : []
      content {
        noncurrent_days = noncurrent_version_expiration.value.days
      }
    }
  }
}

# Blocks public access to the S3 bucket to enhance security.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
