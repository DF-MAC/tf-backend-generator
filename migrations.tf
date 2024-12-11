# --------------------------------------------------------------------------------------------------
# Migrations to 0.7.0
# --------------------------------------------------------------------------------------------------

# This block indicates that the `aws_kms_key.replica` resource's reference has been updated in the Terraform configuration.
# The resource that was previously referenced without an index is now specifically referenced with an index [0],
# indicating it's the first (or possibly the only) element in a list or a set of resources. This change might be due
# to a modification in how resources are defined or handled in the configuration, perhaps moving from a singular resource
# to a more dynamic, possibly count-based, creation method.
moved {
  from = aws_kms_key.replica
  to   = aws_kms_key.replica[0]
}

# Similar to the `aws_kms_key.replica` move, this statement updates the Terraform state to reflect that the
# `aws_s3_bucket.replica` resource is now explicitly indexed. This is useful when configurations change to
# support multiple instances of a resource type, necessitating the need to access specific instances by index.
moved {
  from = aws_s3_bucket.replica
  to   = aws_s3_bucket.replica[0]
}

# This move updates the location of `aws_s3_bucket_public_access_block.replica` in a similar manner to the previous entries.
# It's another example of specifying that the resource now requires an explicit index when being referenced, likely due to
# a change in the configuration that supports or requires specifying multiple `aws_s3_bucket_public_access_block` resources.
moved {
  from = aws_s3_bucket_public_access_block.replica
  to   = aws_s3_bucket_public_access_block.replica[0]
}

# Lastly, the `aws_s3_bucket_policy.replica_force_ssl` move updates the Terraform state to acknowledge that this resource's
# reference now includes an explicit index. This change suggests that the configuration has been adjusted to potentially
# manage multiple bucket policies in a more dynamic fashion, necessitating the use of indices to reference specific policies.
moved {
  from = aws_s3_bucket_policy.replica_force_ssl
  to   = aws_s3_bucket_policy.replica_force_ssl[0]
}
