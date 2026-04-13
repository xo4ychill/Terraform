#!/bin/bash
set -e

DIR=/data/providers
mkdir -p $DIR

aws s3 sync s3://$S3_BUCKET/providers $DIR || true

cd /tmp

cat <<EOF > main.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
    random = { source = "hashicorp/random" }
  }
}
EOF

terraform init
terraform providers mirror $DIR

aws s3 sync $DIR s3://$S3_BUCKET/providers --delete

nginx -g "daemon off;"