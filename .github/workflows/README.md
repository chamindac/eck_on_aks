# GitHub Actions Pipeline Structure (AKS + Multi-Environment Design)

This repository uses a modular GitHub Actions design inspired by Azure DevOps multi-stage pipelines.

The key goal is:
- One main workflow per application (entry point)
- Reusable environment-based workflows
- Fully scalable Dev → QA → Prod model
- No duplication of deployment logic

---

# Core Idea

We use a **single entry pipeline**:

```
eck_on_aks.yaml
```

This is the ONLY workflow manually triggered or CI-triggered.

All logic is delegated to reusable workflows.

---

# Folder Structure
Example only. Actual implmentation may be diffrent from below structure.
```
.github/
├── workflows/
│   ├── eck_on_aks.yml          # SINGLE entry pipeline
│
│   └── reusable/
│       ├── workflows/
│       │   ├── deploy.yml
│       │   ├── destroy.yml
│       │
│       ├── jobs/
│       │   ├── terraform.yml
│       │   ├── deploy-services.yml
│       │   ├── healthcheck.yml
│       │
│       ├── actions/
│       │   ├── install-terraform/
│       │   ├── azure-login/
│       │   ├── kubectl/
│       │
│       └── steps/
│           ├── terraform-init.yml
│           ├── terraform-plan.yml
│           ├── terraform-apply.yml

```
---

# How Execution Works

## 1. Single Entry Workflow

```yaml
# eck_on_aks.yml
on:
  workflow_dispatch:
    inputs:
      environment:
        required: true
        type: choice
        options:
          - dev
          - qa
          - prod-eus
          - prod-aue

jobs:
  deploy:
    uses: ./.github/workflows/reusable/workflows/deploy.yml
    with:
      environment: ${{ inputs.environment }}
```

---

## 2. Reusable Deployment Workflow

All environments call the same deployment logic:

```yaml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string

jobs:

  deploy-tf-plan:
    environment: ${{ inputs.environment }}

  deploy-tf-apply:
    needs: deploy-tf-plan
    environment: ${{ inputs.environment }}

  deploy-services:
    needs: deploy-tf-apply
    environment: ${{ inputs.environment }}

  healthcheck:
    needs: deploy-services
    environment: ${{ inputs.environment }}

  destroy-tf-plan:
    needs: healthcheck
    environment: ${{ inputs.environment }}

  destroy-tf-apply:
    needs: destroy-tf-plan
    environment: ${{ inputs.environment }}
```

---

# Environment Strategy (GitHub Environments)

Each environment in GitHub contains:

- Secrets (Azure credentials, kubeconfig, etc.)
- Variables (resource group, cluster name, region)
- Approval rules (manual gates for prod)

Example:

| Environment | Purpose |
|------------|--------|
| dev        | Development |
| qa         | Testing / QA |
| prod-eus   | Production EU |
| prod-aue   | Production AU |

---

# Execution Flow

Example QA flow:

```
Approval (QA Environment)
   ↓
Deploy Terraform Plan
   ↓
Approval (QA Environment)
   ↓
Deploy Terraform Apply
   ↓
Approval (QA Environment)
   ↓
Deploy Services
   ↓
Approval (QA Environment)
   ↓
Health Check
   ↓
Approval (QA Environment)
   ↓
Destroy Terraform Plan
   ↓
Approval (QA Environment)
   ↓
Destroy Terraform Apply
```

---

# Key Design Benefits

- ✔ Single entry workflow (`check_on_aks.yml`)
- ✔ No duplication of environment pipelines
- ✔ Fully reusable deployment logic
- ✔ Environment-based approvals using GitHub Environments
- ✔ Easy to add new environments (just add new env + config)
- ✔ Clean separation of:
  - workflows (entry point)
  - reusable workflows (logic)
  - environment definitions (dev/qa/prod)

---

# Azure DevOps Mapping

| Azure DevOps | GitHub Actions |
|-------------|----------------|
| Multi-stage pipeline | Reusable workflow chain |
| Variable Groups | GitHub Environments |
| Stages | Jobs |
| Templates | Reusable workflows |
| Manual approval task | Environment approvals |

---

# Summary

This architecture standardizes everything around:

- ONE pipeline entry point
- MANY environments
- ONE reusable deployment engine

Scaling is achieved by adding environments, not duplicating pipelines.
