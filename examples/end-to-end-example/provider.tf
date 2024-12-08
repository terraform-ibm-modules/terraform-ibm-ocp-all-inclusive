# IBM provider used to provision IBM Cloud resources
provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  visibility       = var.visibility
}

# Init cluster config for helm and kubernetes providers
data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_all_inclusive.cluster_id
  resource_group_id = module.ocp_all_inclusive.resource_group_id
  config_dir        = "${path.module}/kubeconfig"
}

# Helm provider used to deploy cluster-proxy and observability agents
provider "helm" {
  kubernetes {
    host  = data.ibm_container_cluster_config.cluster_config.host
    token = data.ibm_container_cluster_config.cluster_config.token
  }
  # IBM Cloud credentials are required to authenticate to the helm repo
  registry {
    url      = "oci://icr.io/ibm/observe/logs-agent-helm"
    username = "iamapikey"
    password = var.ibmcloud_api_key
  }
}

# Kubernetes provider used to create kube namespace(s)
provider "kubernetes" {
  host  = data.ibm_container_cluster_config.cluster_config.host
  token = data.ibm_container_cluster_config.cluster_config.token
}
