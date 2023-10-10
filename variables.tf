##############################################################################
# Common Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "An IBM Cloud API key with permissions to provision resources."
  type        = string
  sensitive   = true
}

variable "resource_group_id" {
  type        = string
  description = "The IBM Cloud resource group ID to provision all resources in."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where all resources will be provisioned."
}

##############################################################################
# VPC Variables
##############################################################################

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to use."
}

variable "vpc_subnets" {
  type = map(list(object({
    id         = string
    zone       = string
    cidr_block = string
  })))
  description = "Subnet metadata by VPC tier."
}

variable "verify_worker_network_readiness" {
  type        = bool
  description = "By setting this to true, a script will run kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, this should be set to false."
  default     = true
}

##############################################################################
# OCP Cluster Variables
##############################################################################

variable "cluster_name" {
  type        = string
  description = "The name to give the OCP cluster provisioned by the module."
}

variable "ocp_version" {
  type        = string
  description = "The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. If no value is passed, or the string 'latest' is passed, the current latest OCP version will be used."
  default     = null

  validation {
    condition = anytrue([
      var.ocp_version == null,
      var.ocp_version == "latest",
      var.ocp_version == "4.10",
      var.ocp_version == "4.11",
      var.ocp_version == "4.12",
      var.ocp_version == "4.13",
    ])
    error_message = "The specified ocp_version is not one of the validated versions."
  }
}

variable "worker_pools" {
  type = list(object({
    subnet_prefix = optional(string)
    vpc_subnets = optional(list(object({
      id         = string
      zone       = string
      cidr_block = string
    })))
    pool_name         = string
    machine_type      = string
    workers_per_zone  = number
    resource_group_id = optional(string)
    labels            = optional(map(string))
    minSize           = optional(number)
    maxSize           = optional(number)
    enableAutoscaling = optional(bool)
    boot_volume_encryption_kms_config = optional(object({
      crk             = string
      kms_instance_id = string
      kms_account_id  = optional(string)
    }))
  }))
  default = [
    {
      subnet_prefix     = "zone-1"
      pool_name         = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type      = "bx2.4x16"
      workers_per_zone  = 2
      minSize           = 1
      maxSize           = 3
      enableAutoscaling = true
      labels            = {}
    },
    {
      subnet_prefix     = "zone-2"
      pool_name         = "zone-2"
      machine_type      = "bx2.4x16"
      workers_per_zone  = 2
      minSize           = 1
      maxSize           = 3
      enableAutoscaling = true
      labels            = { "dedicated" : "zone-2" }
    },
    {
      subnet_prefix     = "zone-3"
      pool_name         = "zone-3"
      machine_type      = "bx2.4x16"
      workers_per_zone  = 2
      minSize           = 1
      maxSize           = 3
      enableAutoscaling = true
      labels            = { "dedicated" : "zone-3" }
    }
  ]
  description = "List of worker pools"
  validation {
    error_message = "Please provide value for minSize and maxSize while enableAutoscaling is set to true."
    condition = length(
      flatten(
        [
          for worker in var.worker_pools :
          worker if worker.enableAutoscaling == true && worker.minSize != null && worker.maxSize != null
        ]
      )
      ) == length(
      flatten(
        [
          for worker in var.worker_pools :
          worker if worker.enableAutoscaling == true
        ]
      )
    )
  }
  validation {
    condition     = length([for worker_pool in var.worker_pools : worker_pool if(worker_pool.subnet_prefix == null && worker_pool.vpc_subnets == null) || (worker_pool.subnet_prefix != null && worker_pool.vpc_subnets != null)]) == 0
    error_message = "Please provide exactly one of subnet_prefix or vpc_subnets. Passing neither or both is invalid."
  }
}

variable "cluster_tags" {
  type        = list(string)
  description = "List of metadata labels to add to cluster."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "Optional list of access management tags to add to the OCP Cluster created by this module."
  default     = []
}

variable "cluster_ready_when" {
  type        = string
  description = "The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady"
  default     = "IngressReady"
  # Set to "Normal" once provider fixes https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4214
  #   default     = "Normal"

  validation {
    condition     = contains(["MasterNodeReady", "OneWorkerNodeReady", "Normal", "IngressReady"], var.cluster_ready_when)
    error_message = "The input variable cluster_ready_when must be one of: \"MasterNodeReady\", \"OneWorkerNodeReady\", \"Normal\" or \"IngressReady\"."
  }
}

variable "disable_public_endpoint" {
  type        = bool
  description = "Flag indicating that the public endpoint should be disabled"
  default     = false
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = "cloud_pak"
}

variable "force_delete_storage" {
  type        = bool
  description = "Delete attached storage when destroying the cluster - Default: false"
  default     = false
}

variable "use_existing_cos" {
  type        = bool
  description = "COS is required to back up the OpenShift internal registry. Set this to true and pass a value for var.existing_cos_id if you want to use an existing COS instance."
  default     = false
}

variable "cos_name" {
  type        = string
  description = "The name to give the COS instance that will be provisioned by this module if var.use_existing_cos is false. COS is required to back up the OpenShift internal registry."
  default     = null
}

variable "existing_cos_id" {
  type        = string
  description = "The COS ID of an already existing COS instance which will be used to back up the OpenShift internal registry. Required if var.use_existing_cos is true."
  default     = null
}

variable "addons" {
  type = object({
    alb-oauth-proxy           = optional(string)
    debug-tool                = optional(string)
    image-key-synchronizer    = optional(string)
    istio                     = optional(string)
    openshift-data-foundation = optional(string)
    static-route              = optional(string)
    cluster-autoscaler        = optional(string)
    vpc-block-csi-driver      = optional(string)
  })
  description = "List of all addons supported by the ocp cluster."
  default     = null
}


##############################################################################
# Key Protect Variables
##############################################################################

variable "existing_key_protect_instance_guid" {
  type        = string
  description = "The GUID of an existing Key Protect instance which will be used for cluster encryption. If no value passed, cluster data is stored in the Kubernetes etcd, which ends up on the local disk of the Kubernetes master (not recommended)."
  default     = null
}

variable "existing_key_protect_root_key_id" {
  type        = string
  description = "The Key ID of a root key, existing in the Key Protect instance passed in var.existing_key_protect_instance_guid, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the secrets in the cluster. Required if value passed for var.existing_key_protect_instance_guid."
  default     = null
}

variable "key_protect_use_private_endpoint" {
  type        = bool
  description = "Set as true to use the Private endpoint when communicating between cluster and Key Protect Instance."
  default     = true
}

##############################################################################
# OCP Worker Variables
##############################################################################

variable "ignore_worker_pool_size_changes" {
  type        = bool
  description = "Enable if using worker autoscaling. Stops Terraform managing worker count"
  default     = false
}

##############################################################################
# LogDNA Agent Variables
##############################################################################

variable "logdna_instance_name" {
  type        = string
  description = "The name of the LogDNA instance to point the LogDNA agent to. If left at null, no agent will be deployed."
  default     = null
}

variable "logdna_ingestion_key" {
  type        = string
  description = "Ingestion key for the LogDNA agent to communicate with the instance."
  sensitive   = true
  default     = null
}

variable "logdna_resource_group_id" {
  type        = string
  description = "Resource group id that the LogDNA instance is in. If left at null, the value of var.resource_group_id will be used."
  default     = null
}

variable "logdna_agent_version" {
  type        = string
  description = "Optionally override the default LogDNA agent version. If the value is null, this version is set to the version of 'logdna_agent_version' variable in the Observability agents module. To list available versions, run: `ibmcloud cr images --restrict ext/logdna-agent`."
  default     = null
}

##############################################################################
# Sysdig Agent Variables
##############################################################################

variable "sysdig_instance_name" {
  type        = string
  description = "The name of the Sysdig instance to point the Sysdig agent to. If left at null, no agent will be deployed."
  default     = null
}

variable "sysdig_access_key" {
  type        = string
  description = "Access key for the Sysdig agent to communicate with the instance."
  sensitive   = true
  default     = null
}

variable "sysdig_resource_group_id" {
  type        = string
  description = "Resource group id that the Sysdig instance is in. If left at null, the value of var.resource_group_id will be used."
  default     = null
}

variable "sysdig_agent_version" {
  type        = string
  description = "Optionally override the default Sysdig agent version. If the value is null, this version is set to the version of 'sysdig_agent_version' variable in the Observability agents module. To list available versions, run: `ibmcloud cr images --restrict ext/sysdig/agent`."
  default     = null
}
