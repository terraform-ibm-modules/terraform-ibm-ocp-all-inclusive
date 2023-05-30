terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.51.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    external = {
      source  = "hashicorp/external"
      version = ">= 2.2.3"
    }
    # tflint-ignore: terraform_unused_required_providers
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
    # tflint-ignore: terraform_unused_required_providers
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.3"
    }
    # tflint-ignore: terraform_unused_required_providers
    null = {
      version = ">= 3.2.1"
    }
    # tflint-ignore: terraform_unused_required_providers
    time = {
      version = ">= 0.9.1"
    }
  }
}
