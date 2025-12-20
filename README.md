# Terraform AWS Portfolio Environment

This repository defines a small, production‑style AWS environment using Terraform, designed to showcase Infrastructure as Code, modular design, and CI/CD‑friendly structure for DevOps and Cloud roles.

## Architecture Overview

The environment models a simple web application stack:

- One VPC with separate public and private subnets
- A single EC2 instance in the public subnet for the app tier
- A static website hosted on S3
- Security groups enforcing least‑privilege network access

The code is organized into reusable Terraform modules and environment‑specific root configurations (`dev`, `prod`).

### High‑Level Design

- **Network**
  - 1 VPC (e.g., `10.0.0.0/16`)
  - 1 public subnet (e.g., `10.0.1.0/24`) for the EC2 app instance
  - 1 private subnet (e.g., `10.0.2.0/24`) reserved for future backend services
  - Internet Gateway and a NAT Gateway for outbound internet access from private subnets
- **Compute**
  - 1 EC2 instance (t3.micro by default) running in the public subnet
  - User data script to bootstrap the application (e.g., simple web page)
- **Static Website**
  - 1 S3 bucket configured for static website hosting (index + error pages)
- **Security**
  - Web security group allowing HTTP/HTTPS from the internet
  - SSH security group allowing SSH from a configurable CIDR range
  - Default outbound egress to the internet for updates and package downloads

## Repository Structure

├── modules/
│ ├── network/ # VPC + public/private subnets (wraps terraform-aws-modules/vpc)
│ ├── security_groups/ # Web + SSH security groups
│ ├── ec2_app/ # Single EC2 instance (wraps terraform-aws-modules/ec2-instance)
│ └── s3_static_site/ # Static S3 website (wraps terraform-aws-modules/s3-bucket)
└── environments/
├── dev/
│ ├── main.tf # Root module wiring dev environment together
│ ├── variables.tf # Dev-specific variables (region, CIDRs, sizes)
│ └── backend.tf # Remote state backend (S3 + DynamoDB)
└── prod/


Each environment is a separate root module with its own Terraform state, while the `modules` directory holds reusable building blocks.

## Modules

### `modules/network`

Encapsulates network primitives using the official `terraform-aws-modules/vpc/aws` module:

- Creates VPC, public subnet, private subnet
- Attaches an Internet Gateway
- Configures a single NAT Gateway
- Outputs:
  - `vpc_id`
  - `public_subnet_id`
  - `private_subnet_id`

### `modules/security_groups`

Defines security groups for:

- Web traffic:
  - Allow HTTP (80) and HTTPS (443) from `0.0.0.0/0`
- SSH access:
  - Allow SSH (22) from a configurable CIDR (e.g., your IP)

Outputs:

- `web_sg_id`
- `ssh_sg_id`

### `modules/ec2_app`

Wraps `terraform-aws-modules/ec2-instance/aws` to create a single EC2 instance:

- Configurable AMI ID and instance type
- Launched into the public subnet
- Attached to the web and SSH security groups
- Optional user data script for bootstrapping

Outputs:

- `instance_id`
- `public_ip`

### `modules/s3_static_site`

Wraps `terraform-aws-modules/s3-bucket/aws` to create:

- An S3 bucket with static website hosting enabled
- Public read access for website content (for demo purposes)
- Outputs `bucket_id` and `website_endpoint`

## Usage

From the `environments/dev` directory:

```shell
cd environments/dev
Initialize backend and providers

terraform init
Review the execution plan

terraform plan -var="ami_id=ami-xxxxxxxx" -var="unique_suffix=yourinitials-dev"
Apply the changes

terraform apply -var="ami_id=ami-xxxxxxxx" -var="unique_suffix=yourinitials-dev"
```

After apply, Terraform will output:

- `ec2_public_ip` – you can SSH and/or browse to the app
- `static_site_url` – the S3 static website endpoint

To destroy the environment:

```shell
terraform destroy -var="ami_id=ami-xxxxxxxx" -var="unique_suffix=yourinitials-dev"
```


## What This Demonstrates

This project is designed as a portfolio artifact to highlight:

- Infrastructure as Code with Terraform and AWS
- Modular design (network, security, compute, storage) and reuse across environments
- Environment separation via dedicated root modules and state
- Clear inputs/outputs and tagging strategy for real‑world operations

It can be extended with:

- RDS or other managed databases in the private subnet
- CloudFront in front of the S3 static site
- CI/CD pipelines (GitHub Actions) that run `fmt`, `validate`, `plan`, and security scans (e.g., Checkov/tfsec) on pull requests.
