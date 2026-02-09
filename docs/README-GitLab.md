# GitLab CI/CD Pipeline Documentation

This document provides comprehensive documentation for the GitLab CI/CD pipeline designed for managing infrastructure as code (IaC) using Ansible and Terraform. The pipeline automates the complete lifecycle: validation, planning, provisioning, and configuration of infrastructure across multiple environments (dev, prod).

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Workflow Triggers](#workflow-triggers)
- [Docker Image](#docker-image)
- [Pipeline Stages](#pipeline-stages)
- [Input Variables](#input-variables)
- [Jobs](#jobs)
  - [generate-config](#generate-config)
  - [trigger-child](#trigger-child)
  - [build_deploy_runner_image](#build_deploy_runner_image)
  - [lint_and_plan](#lint_and_plan)
  - [provision](#provision)
  - [configure](#configure)
- [Caching Strategy](#caching-strategy)
- [Artifacts](#artifacts)
- [Security Considerations](#security-considerations)
- [Usage Guide](#usage-guide)

## Overview

The GitLab CI/CD pipeline is structured using a **parent-child pipeline architecture** that provides:

- **Modular Design**: Parent pipeline handles configuration generation; child pipeline executes deployment workflow
- **Multi-Environment Support**: Deploy to different environments (dev, prod) with a single configuration
- **Automated Validation**: Automatic linting of Ansible playbooks and Terraform configuration validation
- **Redundancy Prevention**: Prevents redundant pipeline runs when commits are already tagged
- **Safe Deployments**: Manual approval required for infrastructure changes and configuration steps

## Architecture

The pipeline uses a **two-file architecture**:

### Parent Pipeline (`.gitlab-ci.yml`)

Controls the overall workflow:
- **generate-config**: Generates dynamic configuration with Docker image version tags and checks for redundant runs
- **trigger-child**: Triggers the child pipeline with environment configuration

### Child Pipeline (`.gitlab/ci/build_plan_provision_configure.yml`)

Executes the deployment workflow:
- **build_runner**: Builds and pushes Docker image to Docker Hub
- **lint-and-plan**: Validates Ansible playbooks and generates Terraform plan
- **provision**: Applies infrastructure changes
- **configure**: Configures provisioned resources with Ansible

The pipeline is configured to run under the following conditions:
- **Manual Trigger**: Via the GitLab UI (`CI_PIPELINE_SOURCE == "web"`).
- **Scheduled Pipelines**: When a scheduled pipeline is executed (`CI_PIPELINE_SOURCE == "schedule"`).
- **Default Branch Pushes**: Automatically on pushes to the default branch (e.g., `main` or `master`) (`CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH`).

## Workflow Triggers

The pipeline runs automatically or manually in the following scenarios:

- **Manual Trigger**: Execute from GitLab UI (`CI_PIPELINE_SOURCE == "web"`) - allows on-demand deployments
- **Scheduled Pipelines**: Execute at scheduled times configured in GitLab (`CI_PIPELINE_SOURCE == "schedule"`)
- **Default Branch Pushes**: Automatic execution on commits to the default branch (`main`) - validates code on every merge
- **Tag Creation**: Automatic execution on git tags (`CI_COMMIT_TAG != null`) - triggers Docker image builds for releases

## Docker Image

The pipeline utilizes a custom Docker image: `huddlesk/uv-ansible-terraform-alpine`

### Image Contents
- **uv**: A fast Python dependency manager for managing dependencies
- **Ansible**: Configuration management tool for post-deployment configuration
- **Terraform**: Infrastructure provisioning and state management
- **Git**: Version control integration
- **Alpine Linux Base**: Lightweight container image

### Image Tag Format
The image tag follows the format: `MAJOR-UV_VERSION-ANSIBLE_VERSION-TERRAFORM_VERSION`

Example: `0-10.2-2.1-14.2`
- MAJOR version: Pipeline/image evolution indicator
- uv version: 10.2
- Ansible version: 2.1
- Terraform version: 14.2

The version tags ensure consistent tooling across all CI/CD pipeline runs, preventing tool version drift and related issues.

## Pipeline Stages

The child pipeline is structured into **four distinct stages** executed sequentially:

### Stage 1: `build_runner`
Builds and publishes the Docker image to Docker Hub
- Triggered: Only when commits are tagged
- Purpose: Ensure CI runners have the latest tools with specific versions

### Stage 2: `lint-and-plan`
Validates code and previews infrastructure changes
- Validates Ansible playbooks with ansible-lint
- Generates Terraform execution plan (without applying changes)
- Caches Terraform providers for faster subsequent runs

### Stage 3: `provision`
Applies approved infrastructure changes
- Manually triggered after plan review
- Applies the exact Terraform plan generated in previous stage
- No new planning - uses pre-generated plan for safety

### Stage 4: `configure`
Executes post-deployment configuration
- Manually triggered after infrastructure is provisioned
- Runs Ansible playbooks to configure provisioned resources
- Requires SSH access to provisioned hosts

## Input Variables

An input variable named `environment` is defined, allowing users to specify the deployment target when triggering the pipeline manually from the GitLab UI.

### `environment` Variable
- **Type**: `string`
- **Options**: `"dev"`, `"prod"`
- **Default**: `"dev"`
- **Description**: Select the target environment for deployment
- **Usage**: Targets environment-specific Terraform configurations and Ansible inventories

This variable is passed from the parent pipeline to the child pipeline and used to:
- Select which Terraform environment directory to use
- Choose the appropriate Ansible inventory file
- Determine which backend configuration to apply
- Control which infrastructure modifications are deployed

## Jobs

## Jobs

### Parent Pipeline Jobs

#### `generate-config` Job
- **Stage**: `.pre`
- **Purpose**: Generates dynamic pipeline configuration and prevents redundant pipeline runs
- **Responsibilities**:
  - Fetches all git tags for version information
  - Creates configuration file with Docker image tag
  - Checks if current commit is already tagged (on main branch only)
  - Skips redundant pipeline if HEAD matches the latest tag
  - Generates `generated-config.yml` for child pipeline consumption
- **Artifacts**: `generated-config.yml` - Configuration file passed to child pipeline
- **Error Handling**: Fails pipeline (exit 1) if commit is redundantly tagged on main branch

#### `trigger-child` Job
- **Stage**: `trigger_child_pipeline`
- **Purpose**: Orchestrates the child pipeline execution
- **Configuration**:
  - Includes child pipeline from `.gitlab/ci/build_plan_provision_configure.yml`
  - Passes `environment` input variable to child pipeline
  - Includes generated configuration artifact from `generate-config` job
  - Uses `strategy: depend` to wait for child pipeline completion
- **Dependencies**: Requires `generate-config` job artifacts
- **Behavior**: Parent pipeline completes only after child pipeline succeeds or fails

### Child Pipeline Jobs

#### `build_deploy_runner_image` Job
- **Stage**: `build_runner`
- **Purpose**: Builds and publishes Docker image to Docker Hub
- **When**: Only executes when commit is tagged (`CI_COMMIT_TAG != null`)
- **Services**: Uses Docker-in-Docker (dind) for building images
- **Setup**:
  - Installs git via apk
  - Authenticates with Docker Hub using `DOCKERHUB_TOKEN` and `DOCKERHUB_USERNAME` variables
  - Determines image tag from commit tag or latest git tag
- **Process**:
  - Builds Docker image from root `Dockerfile`
  - Tags image with determined version
  - Pushes image to Docker Hub
- **Dependencies**: None (executes independently)
- **Alternative Rules** (commented for reference):
  - Manual trigger from GitLab UI
  - Automatic on main branch commits

#### `lint_and_plan` Job
- **Stage**: `lint-and-plan`
- **Purpose**: Validates Ansible playbooks and previews infrastructure changes
- **Environment**: Sets `TF_VAR_env` to selected environment
- **Before Script**:
  - Creates Terraform plugin cache directory
  - Prints version information for debugging
- **Ansible Linting**:
  - Runs `ansible-lint site.yml` to validate playbook syntax and best practices
  - Saves output to `ansible-lint.txt`
- **Terraform Planning**:
  - Initializes Terraform with backend configuration
  - Creates execution plan without applying changes
  - Saves plan to `tfplan` for later provisioning stage
  - Enables pipeline fail (`set -o pipefail`) for error detection
- **Caching**:
  - Caches `.terraform` directory and plugin cache
  - Invalidates cache when dependency lockfiles change
  - Policy: `pull-push` (restores and saves cache)
- **Artifacts**:
  - `ansible/ansible-lint.txt`: Linting output for review
  - `terraform/environments/$ENV/tfplan`: Terraform execution plan
  - Retention: 3 days
  - Saved on success and failure (for debugging)

#### `provision` Job
- **Stage**: `provision`
- **Purpose**: Applies Terraform plan to provision infrastructure
- **Trigger**: Manually triggered (`when: manual`) - requires explicit approval
- **Safety Features**:
  - Uses pre-generated plan from `lint_and_plan` (no new plan generation)
  - Prevents infrastructure drift from unexpected changes
  - Applies exact plan that was reviewed
- **Process**:
  - Initializes Terraform with backend configuration
  - Applies saved plan with automatic approval (`terraform apply -auto-approve tfplan`)
- **Dependencies**: Requires `lint_and_plan` job to complete successfully and provide `tfplan` artifact

#### `configure` Job
- **Stage**: `configure`
- **Purpose**: Configures provisioned infrastructure using Ansible playbooks
- **Trigger**: Manually triggered (`when: manual`) - requires explicit approval
- **Setup**:
  - Downloads GitLab Secure Files installer
  - Retrieves SSH private key from secure files
  - Creates `~/.ssh` directory with proper permissions (700)
  - Moves SSH key to `~/.ssh/id_ed25519` with restrictive permissions (600)
- **Configuration**:
  - Sets `ANSIBLE_HOST_KEY_CHECKING` to `False` (safe for CI with controlled hosts)
- **Execution**:
  - Runs `ansible-playbook` with environment-specific inventory
  - Uses inventory file: `inventory-$ENV.ini`
  - Applies playbook: `site.yml`
- **Dependencies**: Requires `provision` job to complete successfully
- **Security**: SSH keys managed via GitLab Secure Files, never stored in repository

## Caching Strategy

-   **Caching**: Terraform plugins and providers are cached to optimize pipeline execution times. The cache policy is `pull-push`, meaning it attempts to restore the cache before the job and saves it afterward.
## Artifacts

The pipeline saves important outputs as artifacts for review and troubleshooting:

### Lint and Plan Stage Artifacts
- **ansible-lint.txt**: Ansible linting output
  - Path: `ansible/ansible-lint.txt`
  - Purpose: Review Ansible validation results
  - Useful for: Identifying playbook syntax issues

- **tfplan**: Terraform execution plan
  - Path: `terraform/environments/$ENV/tfplan`
  - Purpose: Used by provision stage for exact plan application
  - Useful for: Reviewing proposed infrastructure changes before applying

### Artifact Retention
- **Expiration**: 3 days
- **Saved On**: Success and failure
- **Purpose**: Allows debugging failed jobs even after completion
- **Access**: Available in GitLab UI under "Artifacts" tab for each job

### Artifact Usage
- Artifacts enable the separation of `lint-and-plan` and `provision` stages
- Allows infrastructure review before deployment
- Ensures provision stage applies exact plan that was reviewed (no drift)

## Security Considerations

The pipeline implements several security best practices:

### Credential Management
- **SSH Keys**: Managed via GitLab Secure Files (not stored in repository)
  - Retrieved only during `configure` stage
  - Placed with restrictive permissions (`chmod 600`)
  - Specific to environment and deployment

- **Docker Hub Credentials**: Stored as CI/CD variables
  - `DOCKERHUB_USERNAME`: Docker Hub account
  - `DOCKERHUB_TOKEN`: Authentication token
  - Not exposed in logs or output

### Pipeline Security
- **Manual Approvals**: Infrastructure changes and configuration require explicit approval
  - `provision` stage: Manually triggered
  - `configure` stage: Manually triggered
  - Prevents accidental or unauthorized changes

- **No Hardcoded Secrets**: All sensitive data via GitLab CI/CD variables or Secure Files

### SSH Host Key Verification
- `ANSIBLE_HOST_KEY_CHECKING` set to `False`
- Safe for CI as infrastructure is provisioned by Terraform in same pipeline
- Eliminates SSH host key prompts that would hang CI

### Terraform State Management
- Backend configuration targets specific AWS S3 bucket per environment
- State files contain sensitive data and should not be committed
- Access controlled via AWS IAM and bucket policies

### Log Sanitization
- Pipeline commands don't output credentials
- Version information printed for debugging without sensitive data
- Artifacts contain only results, not configuration files with secrets

## Usage Guide

### Prerequisites
1. GitLab repository with this pipeline configuration
2. AWS account with appropriate IAM permissions
3. Docker Hub account for pushing images
4. SSH key pair for Ansible-to-host communication
5. GitLab Secure Files configured with SSH private key

### Step-by-Step Deployment

#### 1. Create/Update Environment Configuration
```bash
# Create environment-specific Terraform configuration
mkdir -p terraform/environments/prod
cp terraform/environments/dev/* terraform/environments/prod/
# Update terraform/environments/prod/terraform.tfvars with prod values
```

#### 2. Create Ansible Inventory
```bash
# Create environment-specific inventory
cp ansible/inventory-dev.ini ansible/inventory-prod.ini
# Update hosts and variables for prod environment
```

#### 3. Configure GitLab CI/CD Variables
In GitLab project settings → CI/CD → Variables:
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Your Docker Hub authentication token

#### 4. Configure GitLab Secure Files
In GitLab project settings → CI/CD → Secure Files:
- Upload `id_ed25519_npp` (Ansible SSH private key)

#### 5. Create Release Tag
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
# Triggers: build_deploy_runner_image job
```

#### 6. Trigger Manual Pipeline (for existing images)
1. Go to GitLab → CI/CD → Pipelines
2. Click "Run pipeline"
3. Select environment: `dev` or `prod`
4. Click "Run pipeline"

#### 7. Review Plan
- Wait for `lint_and_plan` job to complete
- Review `tfplan` artifact for infrastructure changes
- Review `ansible-lint.txt` for any Ansible issues

#### 8. Approve Provisioning
1. Click on `provision` job
2. Click "Play" button to approve execution
3. Monitor logs during infrastructure provisioning

#### 9. Approve Configuration
1. Wait for `provision` job to complete
2. Click on `configure` job
3. Click "Play" button to approve Ansible execution
4. Monitor logs during infrastructure configuration

### Troubleshooting

#### Pipeline Skipped on Main Branch
**Symptom**: Pipeline shows as "skipped" on main branch
**Cause**: Current commit matches the latest git tag
**Solution**: Create a new tag with `git tag -a v1.0.1` and push

#### Terraform Plan Shows Unexpected Changes
**Symptom**: tfplan shows resources that shouldn't change
**Cause**: Terraform state drift or configuration differences
**Solution**: 
1. Check terraform/environments/$ENV/terraform.tfvars
2. Run `terraform plan` locally to verify
3. Update tfvars if configuration changed

#### Ansible Configuration Fails
**Symptom**: `configure` job fails with SSH errors
**Cause**: SSH key not configured or host unreachable
**Solution**:
1. Verify SSH key uploaded to GitLab Secure Files
2. Check security groups allow SSH (port 22)
3. Verify inventory file has correct IP addresses

#### Docker Image Build Fails
**Symptom**: `build_deploy_runner_image` fails
**Cause**: Docker Hub credentials invalid or network issue
**Solution**:
1. Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` in variables
2. Test credentials locally: `docker login -u $USER`
3. Check network connectivity to Docker Hub

### Monitoring and Debugging

#### View Pipeline Logs
1. GitLab UI → CI/CD → Pipelines
2. Click pipeline number
3. Click job name to view detailed logs

#### Retrieve Artifacts
1. Click job name
2. Scroll to "Artifacts" section
3. Download files for review

#### Local Testing
```bash
# Test Ansible playbook locally
cd ansible
ansible-lint site.yml

# Test Terraform plan locally
cd terraform/environments/dev
terraform plan -out=tfplan
```
