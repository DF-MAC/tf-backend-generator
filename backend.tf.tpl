terraform {
  backend "s3" {
    bucket         = "%S3_BUCKET%"
    key            = "state/key/path/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "%DYNAMODB_TABLE%"
    encrypt        = true
    kms_key_id     = "%KMS_KEY_ID%"
  }
}
