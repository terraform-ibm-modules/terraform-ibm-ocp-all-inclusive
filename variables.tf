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
  description = "The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. Supports passing the string 'default' (current IKS default recommended version). If no value is passed, it will default to 'default'."
  default     = null

  validation {
    condition = anytrue([
      var.ocp_version == null,
      var.ocp_version == "default",
      var.ocp_version == "4.12",
      var.ocp_version == "4.13",
      var.ocp_version == "4.14",
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
  description = "Whether access to the public service endpoint is disabled when the cluster is created. Does not affect existing clusters. To change a public endpoint to private, create another cluster with the variable set to true or see [Switching to the private endpoint](https://cloud.ibm.com/docs/containers?topic=containers-cs_network_cluster#migrate-to-private-se)."
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

variable "cos_name" {
  type        = string
  description = "Name of the COS instance to provision for OpenShift internal registry storage. New instance only provisioned if 'enable_registry_storage' is true and 'use_existing_cos' is false. Default: '<cluster_name>_cos'"
  default     = null
}

variable "use_existing_cos" {
  type        = bool
  description = "Flag indicating whether or not to use an existing COS instance for OpenShift internal registry storage. Only applicable if 'enable_registry_storage' is true"
  default     = false
}

variable "existing_cos_id" {
  type        = string
  description = "The COS id of an already existing COS instance to use for OpenShift internal registry storage. Only required if 'enable_registry_storage' and 'use_existing_cos' are true"
  default     = null
}

variable "enable_registry_storage" {
  type        = bool
  description = "Set to `true` to enable IBM Cloud Object Storage for the Red Hat OpenShift internal image registry. Set to `false` only for new cluster deployments in an account that is allowlisted for this feature."
  default     = true
}

variable "addons" {
  type = object({
    debug-tool                = optional(string)
    image-key-synchronizer    = optional(string)
    openshift-data-foundation = optional(string)
    vpc-file-csi-driver       = optional(string)
    static-route              = optional(string)
    cluster-autoscaler        = optional(string)
    vpc-block-csi-driver      = optional(string)
  })
  description = "List of all addons supported by the ocp cluster."
  default     = null
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

variable "manage_all_addons" {
  type        = bool
  default     = false
  nullable    = false # null values are set to default value
  description = "Instructs Terraform to manage all cluster addons, even if addons were installed outside of the module. If set to 'true' this module will destroy any addons that were installed by other sources."
}

##############################################################################
# KMS Variables
##############################################################################

variable "existing_kms_instance_guid" {
  type        = string
  description = "The GUID of an existing KMS instance which will be used for cluster encryption. If no value passed, cluster data is stored in the Kubernetes etcd, which ends up on the local disk of the Kubernetes master (not recommended)."
  default     = null
}

variable "existing_kms_root_key_id" {
  type        = string
  description = "The Key ID of a root key, existing in the KMS instance passed in var.existing_kms_instance_guid, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the secrets in the cluster. Required if value passed for var.existing_kms_instance_guid."
  default     = null
}

variable "kms_use_private_endpoint" {
  type        = bool
  description = "Set as true to use the Private endpoint when communicating between cluster and KMS instance."
  default     = true
}

variable "kms_account_id" {
  type        = string
  description = "Id of the account that owns the KMS instance to encrypt the cluster. It is only required if the KMS instance is in another account."
  default     = null
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
# Log Analysis Agent Variables
##############################################################################

variable "log_analysis_enabled" {
  type        = bool
  description = "Deploy IBM Cloud Logging agent"
  default     = true
}

variable "log_analysis_add_cluster_name" {
  type        = bool
  description = "If true, configure the log analysis agent to attach a tag containing the cluster name to all log messages."
  default     = true
}

variable "log_analysis_secret_name" {
  type        = string
  description = "The name of the secret which will store the ingestion key."
  default     = "logdna-agent"
  nullable    = false
}

variable "log_analysis_instance_region" {
  type        = string
  description = "The IBM Log Analysis instance region. Used to construct the ingestion endpoint."
  default     = null
}

variable "log_analysis_ingestion_key" {
  type        = string
  description = "Ingestion key for the Log Analysis agent to communicate with the instance."
  sensitive   = true
  default     = null
}

variable "log_analysis_endpoint_type" {
  type        = string
  description = "Specify the IBM Log Analysis instance endpoint type (public or private) to use. Used to construct the ingestion endpoint."
  default     = "private"
  validation {
    error_message = "The specified endpoint_type can be private or public only."
    condition     = contains(["private", "public"], var.log_analysis_endpoint_type)
  }
}

variable "log_analysis_agent_tags" {
  type        = list(string)
  description = "List of tags to associate with the log analysis agents"
  default     = []
}

variable "log_analysis_agent_custom_line_inclusion" {
  description = "Log Analysis agent custom configuration for line inclusion setting LOGDNA_K8S_METADATA_LINE_INCLUSION. See https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering for more info."
  type        = string
  default     = null
}

variable "log_analysis_agent_custom_line_exclusion" {
  description = "Log Analysis agent custom configuration for line exclusion setting LOGDNA_K8S_METADATA_LINE_EXCLUSION. See https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering for more info."
  type        = string
  default     = null
}

variable "log_analysis_agent_name" {
  description = "Log Analysis agent name. Used for naming all kubernetes and helm resources on the cluster."
  type        = string
  default     = "logdna-agent"
  nullable    = false
}

variable "log_analysis_agent_namespace" {
  type        = string
  description = "Namespace where to deploy the Log Analysis agent. Default value is 'ibm-observe'"
  default     = "ibm-observe"
  nullable    = false
}

variable "log_analysis_agent_tolerations" {
  description = "List of tolerations to apply to Log Analysis agent."
  type = list(object({
    key               = optional(string)
    operator          = optional(string)
    value             = optional(string)
    effect            = optional(string)
    tolerationSeconds = optional(number)
  }))
  default = [{
    operator = "Exists"
  }]
}

##############################################################################
# Cloud Monitoring Agent Variables
##############################################################################

variable "cloud_monitoring_enabled" {
  type        = bool
  description = "Deploy IBM Cloud Monitoring agent"
  default     = true
}

variable "cloud_monitoring_access_key" {
  type        = string
  description = "Access key for the Cloud Monitoring agent to communicate with the instance."
  sensitive   = true
  default     = null
}

variable "cloud_monitoring_secret_name" {
  type        = string
  description = "The name of the secret which will store the access key."
  default     = "sysdig-agent"
  nullable    = false
}

variable "cloud_monitoring_instance_region" {
  type        = string
  description = "The IBM Cloud Monitoring instance region. Used to construct the ingestion endpoint."
  default     = null
}

variable "cloud_monitoring_endpoint_type" {
  type        = string
  description = "Specify the IBM Cloud Monitoring instance endpoint type (public or private) to use. Used to construct the ingestion endpoint."
  default     = "private"
  validation {
    error_message = "The specified endpoint_type can be private or public only."
    condition     = contains(["private", "public"], var.cloud_monitoring_endpoint_type)
  }
}

variable "cloud_monitoring_metrics_filter" {
  type = list(object({
    type = string
    name = string
  }))
  description = "To filter custom metrics, specify the Cloud Monitoring metrics to include or to exclude. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics."
  default     = []
  validation {
    condition     = length(var.cloud_monitoring_metrics_filter) == 0 || can(regex("^(include|exclude)$", var.cloud_monitoring_metrics_filter[0].type))
    error_message = "Invalid input for `cloud_monitoring_metrics_filter`. Valid options for 'type' are: `include` and `exclude`. If empty, no metrics are included or excluded."
  }
}

variable "cloud_monitoring_agent_tags" {
  type        = list(string)
  description = "List of tags to associate with the cloud monitoring agents"
  default     = []
}

variable "cloud_monitoring_add_cluster_name" {
  type        = bool
  description = "If true, configure the cloud monitoring agent to attach a tag containing the cluster name to all metric data."
  default     = true
}

variable "cloud_monitoring_agent_name" {
  description = "Cloud Monitoring agent name. Used for naming all kubernetes and helm resources on the cluster."
  type        = string
  default     = "sysdig-agent"
}

variable "cloud_monitoring_agent_namespace" {
  type        = string
  description = "Namespace where to deploy the Cloud Monitoring agent. Default value is 'ibm-observe'"
  default     = "ibm-observe"
  nullable    = false
}

variable "cloud_monitoring_agent_tolerations" {
  description = "List of tolerations to apply to Cloud Monitoring agent."
  type = list(object({
    key               = optional(string)
    operator          = optional(string)
    value             = optional(string)
    effect            = optional(string)
    tolerationSeconds = optional(number)
  }))
  default = [{
    operator = "Exists"
    },
    {
      operator : "Exists"
      effect : "NoSchedule"
      key : "node-role.kubernetes.io/master"
  }]
}
