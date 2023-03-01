# IBM provider used to provision IBM Cloud resources
provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

# Init cluster config for helm and kubernetes providers
data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_all_inclusive.cluster_id
  resource_group_id = module.ocp_all_inclusive.resource_group_id
}

# Helm provider used to deploy cluster-proxy and observability agents
provider "helm" {
  kubernetes {
    host  = data.ibm_container_cluster_config.cluster_config.host
    token = data.ibm_container_cluster_config.cluster_config.token
  }
}

# Kubernetes provider used to create kube namespace(s)
provider "kubernetes" {
  host  = data.ibm_container_cluster_config.cluster_config.host
  token = data.ibm_container_cluster_config.cluster_config.token
}

# Retrieve IAM access token (required for restapi provider)
data "ibm_iam_auth_token" "token_data" {
}

# restapi provider required by terraform-ibm-key-protect-all-inclusive module
provider "restapi" {
  uri                   = "https:"
  write_returns_object  = false
  create_returns_object = false
  debug                 = false
  headers = {
    Authorization    = data.ibm_iam_auth_token.token_data.iam_access_token
    Bluemix-Instance = module.key_protect_all_inclusive.key_protect_guid
    Content-Type     = "application/vnd.ibm.kms.policy+json"
  }
}
