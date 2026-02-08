# GitLab CI/CD Pipeline Overview

This document explains the CI/CD pipeline defined in `.gitlab-ci.yml`, which is designed for an infrastructure-as-code project leveraging Ansible and Terraform. The pipeline automates the linting, planning, provisioning, and configuration of infrastructure, supporting both manual and scheduled executions.

## Table of Contents
- [Pipeline Purpose](#pipeline-purpose)
- [Workflow Triggers](#workflow-triggers)
- [Docker Image](#docker-image)
- [Pipeline Stages](#pipeline-stages)
- [Input Variables](#input-variables)
- [Jobs](#jobs)
  - [Lint and Plan](#lint-and-plan)
  - [Provision](#provision)
  - [Configure](#configure)
- [Caching and Artifacts](#caching-and-artifacts)
- [Security Considerations](#security-considerations)

## Pipeline Purpose

The primary goal of this pipeline is to provide a robust and automated process for managing infrastructure as code. It ensures code quality through linting, validates infrastructure changes with planning, deploys resources, and configures them post-deployment.

## Workflow Triggers

The pipeline is configured to run under the following conditions:
- **Manual Trigger**: Via the GitLab UI (`CI_PIPELINE_SOURCE == "web"`).
- **Scheduled Pipelines**: When a scheduled pipeline is executed (`CI_PIPELINE_SOURCE == "schedule"`).
- **Default Branch Pushes**: Automatically on pushes to the default branch (e.g., `main` or `master`) (`CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH`).

## Docker Image

The pipeline utilizes a custom Docker image, `huddlesk/uv-ansible-terraform-alpine:0-10.2-2.1-14.1`. This image is built to include:
- `uv`: A fast Python dependency manager.
- `Ansible`: For configuration management.
- `Terraform`: For infrastructure provisioning.
- Other necessary dependencies within an Alpine Linux base.

The image tag `0-10.2-2.1-14.1` indicates the versions of `uv`, `Ansible`, and `Terraform` respectively, ensuring consistent tooling across all CI/CD runs. The final digit is the image's own version.

## Pipeline Stages

The pipeline is structured into three distinct stages, executed sequentially:

1.  **`lint-and-plan`**: Focuses on code quality and infrastructure change validation.
2.  **`provision`**: Responsible for deploying the infrastructure.
3.  **`configure`**: Handles the post-deployment configuration of the provisioned resources.

## Input Variables

An input variable named `environment` is defined, allowing users to specify the deployment target when triggering the pipeline manually from the GitLab UI.

-   **`environment`**:
    -   **Type**: `string`
    -   **Options**: `"dev"`, `"prod"`
    -   **Default**: `"dev"`
    -   **Description**: Selects the environment to deploy to, targeting specific Terraform configurations and Ansible inventories.

## Jobs

### Lint and Plan

-   **Stage**: `lint-and-plan`
-   **Description**: This job performs Ansible linting and generates a Terraform plan.
    -   It uses the `environment` input variable to set `TF_VAR_env` and target the correct Terraform environment.
    -   `ansible-lint` is run against `site.yml`.
    -   `terraform init` is executed to initialize the backend and modules for the selected environment.
    -   `terraform plan -out=tfplan` creates an execution plan, which is saved for the subsequent `provision` stage.
-   **Artifacts**:
    -   `ansible-lint.txt`: Output of the Ansible linting.
    -   `tfplan`: The Terraform execution plan.
-   **Caching**: Caches Terraform providers and modules to speed up subsequent runs. The cache key is based on `terraform/environments/$[[ inputs.environment ]]/.terraform.lock.hcl` to ensure cache invalidation when dependencies change.

### Provision

-   **Stage**: `provision`
-   **Description**: This job applies the Terraform plan to provision the infrastructure.
    -   It is configured to run `when: manual`, requiring explicit user approval to proceed.
    -   It depends on the successful completion of the `lint_and_plan` job to access the `tfplan` artifact.
    -   `terraform init` and `terraform apply -auto-approve tfplan` are executed to apply the pre-generated plan.
-   **Needs**: `lint_and_plan`

### Configure

-   **Stage**: `configure`
-   **Description**: This job executes Ansible playbooks to configure the provisioned infrastructure.
    -   It is also configured to run `when: manual`.
    -   It sets `ANSIBLE_HOST_KEY_CHECKING` to `False` to prevent SSH host key checking issues in CI.
    -   It downloads and sets up the GitLab Secure Files installer to retrieve an SSH private key (`id_ed25519_npp`) for Ansible to connect to the provisioned hosts.
    -   The SSH key is moved to `~/.ssh/id_ed25519` and permissions are set correctly.
    -   `ansible-playbook` is then executed with the appropriate inventory file (`inventory-$[[ inputs.environment ]].ini`) and `site.yml`.
-   **Needs**: `provision`

## Caching and Artifacts

-   **Caching**: Terraform plugins and providers are cached to optimize pipeline execution times. The cache policy is `pull-push`, meaning it attempts to restore the cache before the job and saves it afterward.
-   **Artifacts**: Key outputs such as `ansible-lint.txt` and `tfplan` are saved as artifacts, accessible for review and use in subsequent stages for 3 days, even if the job fails (for debugging purposes).

## Security Considerations

The `configure` stage handles sensitive SSH keys using GitLab Secure Files. The installer retrieves the private key, which is then placed with appropriate permissions (`chmod 600`) for Ansible to use. This method helps in securely managing credentials within the CI environment.
