terraform {
  required_version = ">= 1.9.0"
  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.71.0, < 2.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    external = {
      source  = "hashicorp/external"
      version = ">= 2.2.3, < 3.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0, < 3.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1, < 3.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.3, < 3.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1, < 4.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1, < 1.0.0"
    }
  }
}
