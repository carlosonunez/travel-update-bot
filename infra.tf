terraform {
  backend "s3" {}
  required_providers {
    aws = {
      version = "4.67.0"
    }
  }
}

provider "aws" {}

provider "aws" {
  alias = "aws_acm_cert_region_for_edge"
  region = "us-east-1"
}

data "aws_region" "current" {}

variable "serverless_bucket_name" {
  description = "The bucket into which Serverless will deploy the app."
}

variable "domain_path" {
  description = "The DNS path to affix to the domain_tld."
}

variable "domain_tld" {
  description = "The domain name to use; this is used for creating HTTPS certificates."
}

variable "no_certs" {
  description = "Flag to disable cert provisioning for development deployments."
  default = "false"
}

variable "environment" {
  description = "The environment to which this infrastructure is being deployed."
  default = "test"
}

variable "app_name" {
  description = "The name of the app for which APIs are being built."
}

data "aws_route53_zone" "app_dns_zone" {
  name = "${var.domain_tld}."
}

resource "aws_s3_bucket" "serverless_bucket" {
  bucket = "${var.serverless_bucket_name}-${var.environment}"
  force_destroy = true
}

resource "aws_iam_user" "app" {
  name = "${var.app_name}_api_app_account_${var.environment}"
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

resource "aws_iam_user_policy" "app" {
  name = "${var.app_name}_api_app_account_policy"
  user = aws_iam_user.app.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
        "Action": [
          "s3:ListObjects"
        ],
        "Effect": "Allow",
        "Resource": "*"
     }
  ]
}
EOF
}

resource "aws_acm_certificate" "app_cert" {
  count = var.no_certs == "true" ? 0 : 1
  provider = aws.aws_acm_cert_region_for_edge
  domain_name = "${var.domain_path}.${var.domain_tld}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "app_cert_validation_cname" {
  provider = aws.aws_acm_cert_region_for_edge
  count   = var.no_certs == "true" ? 0 : 1
  name    = tolist(aws_acm_certificate.app_cert.0.domain_validation_options).0.resource_record_name
  type    = tolist(aws_acm_certificate.app_cert.0.domain_validation_options).0.resource_record_type
  zone_id = data.aws_route53_zone.app_dns_zone.id
  records = [tolist(aws_acm_certificate.app_cert.0.domain_validation_options).0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "app_cert" {
  provider = aws.aws_acm_cert_region_for_edge
  count = var.no_certs == "true" ? 0 : 1
  certificate_arn         = aws_acm_certificate.app_cert.0.arn
  validation_record_fqdns = [aws_route53_record.app_cert_validation_cname.0.fqdn]
}

data "aws_ecr_authorization_token" "default" {}

output "app_account_ak" {
  value = aws_iam_access_key.app.id
}

output "app_account_sk" {
  value = aws_iam_access_key.app.secret
}

output "certificate_arn" {
  value = var.no_certs == "true" ? "none" : aws_acm_certificate.app_cert.0.arn
}

output "ecr_repository_password" {
  value = data.aws_ecr_authorization_token.default.password
}
