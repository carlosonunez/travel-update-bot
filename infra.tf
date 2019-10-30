terraform {
  backend "s3" {}
}

// API Gateway requires that ACM certificates reside in us-east-1.
provider "aws" {
  alias = "aws_acm_cert_region_for_edge"
  region = "us-east-1"
}

variable "serverless_bucket_name" {
  description = "The bucket into which Serverless will deploy the app."
}

variable "app_account_name" {
  description = "The name to assign to the IAM user under which the API will run."
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

data "aws_route53_zone" "app_dns_zone" {
  name = "${var.domain_tld}."
}

data "aws_region" "current" {}

resource "aws_s3_bucket" "serverless_bucket" {
  bucket = "${var.serverless_bucket_name}"
}

resource "aws_iam_user" "app" {
  name = "flight_info_botapp_account"
}

resource "aws_iam_access_key" "app" {
  user = "${aws_iam_user.app.name}"
}

resource "aws_iam_user_policy" "app" {
  name = "flight_info_botapp_account_policy"
  user = "${aws_iam_user.app.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
        "Action": ["s3:ListObjects"],
        "Effect": "Allow",
        "Resource": "*"
     }
  ]
}
EOF
}

resource "aws_acm_certificate" "app_cert" {
  count = "${var.no_certs == "true" ? 0 : 1 }"
  provider = aws.aws_acm_cert_region_for_edge
  domain_name = "${var.domain_path}.${var.domain_tld}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "app_cert_validation_cname" {
  provider = aws.aws_acm_cert_region_for_edge
  count   = "${var.no_certs == "true" ? 0 : 1 }"
  name    = "${aws_acm_certificate.app_cert.0.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.app_cert.0.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.app_dns_zone.id}"
  records = ["${aws_acm_certificate.app_cert.0.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "app_cert" {
  provider = aws.aws_acm_cert_region_for_edge
  count = "${var.no_certs == "true" ? 0 : 1 }"
  certificate_arn         = "${aws_acm_certificate.app_cert.0.arn}"
  validation_record_fqdns = ["${aws_route53_record.app_cert_validation_cname.0.fqdn}"]
}

resource "aws_vpc" "lambda_vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_eip" "lambda_inet_outbound" {
  vpc = true
}

resource "aws_internet_gateway" "public_to_inet" {
  vpc_id = "${aws_vpc.lambda_vpc.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.lambda_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.public_to_inet.id}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.lambda_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.private_to_public.id}"
  }
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.lambda_vpc.id}"
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block = "192.168.1.0/24"
}

resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.lambda_vpc.id}"
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block = "192.168.2.0/24"
}

resource "aws_nat_gateway" "private_to_public" {
  allocation_id = "${aws_eip.lambda_inet_outbound.id}"
  subnet_id = "${aws_subnet.private.id}"
}

resource "aws_route_table_association" "private" {
  subnet_id = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "lambda_inet_outbound" {
  name = "lambda_functions"
  description = "Allow outbound Internet access to Lambda functions"
  vpc_id = "${aws_vpc.lambda_vpc.id}"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


output "app_account_ak" {
  value = "${aws_iam_access_key.app.id}"
}

output "app_account_sk" {
  value = "${aws_iam_access_key.app.secret}"
}

output "certificate_arn" {
  value = "${var.no_certs == "true" ? "none" : aws_acm_certificate.app_cert.0.arn}"
}

output "lambda_subnet_id" {
  value = "${aws_subnet.private.id}"
}

output "lambda_security_group" {
  value = "${aws_security_group.lambda_inet_outbound.id}"
}
