terraform {
  required_version = ">= 1.3.0, <1.62.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.62.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
    logdna = {
      source  = "logdna/logdna"
      version = ">= 1.14.2"
    }
  }
}
