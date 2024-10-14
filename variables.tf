##############################################################################
# Common Variables
##############################################################################

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
      var.ocp_version == "4.15",
      var.ocp_version == "4.16",
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
    operating_system  = optional(string)
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
  description = "Whether access to the public service endpoint is disabled when the cluster is created. Does not affect existing clusters. You can't disable a public endpoint on an existing cluster, so you can't convert a public cluster to a private cluster. To change a public endpoint to private, create another cluster with this input set to `true`."
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
  description = "Whether Terraform manages all cluster add-ons, even add-ons installed outside of the module. If set to 'true', this module destroys the add-ons installed by other sources."
}

variable "additional_lb_security_group_ids" {
  description = "Additional security group IDs to add to the load balancers associated with the cluster. These security groups are in addition to the IBM-maintained security group."
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = var.additional_lb_security_group_ids == null ? true : length(var.additional_lb_security_group_ids) <= 4
    error_message = "Please provide at most 4 additional security groups."
  }
}

variable "number_of_lbs" {
  description = "The number of load balancer to associate with the `additional_lb_security_group_names` security group. Must match the number of load balancers that are associated with the cluster"
  type        = number
  default     = 1
  nullable    = false
  validation {
    condition     = var.number_of_lbs >= 1
    error_message = "Specify at least one load balancer."
  }
}

variable "additional_vpe_security_group_ids" {
  description = "Additional security groups to add to all the load balancers. This comes in addition to the IBM maintained security group."
  type = object({
    master   = optional(list(string), [])
    registry = optional(list(string), [])
    api      = optional(list(string), [])
  })
  default = {}
}

variable "disable_outbound_traffic_protection" {
  type        = bool
  description = "Whether to allow public outbound access from the cluster workers. This is only applicable for Red Hat OpenShift 4.15."
  default     = false
}

variable "operating_system" {
  type        = string
  description = "The operating system of the workers in the default worker pool. If no value is specified, the current default version OS will be used. See https://cloud.ibm.com/docs/openshift?topic=openshift-openshift_versions#openshift_versions_available ."
  default     = null
  validation {
    error_message = "RHEL 8 (REDHAT_8_64) or Red Hat Enterprise Linux CoreOS (RHCOS) are the allowed OS values. RHCOS requires VPC clusters created from 4.15 onwards. Upgraded clusters from 4.14 cannot use RHCOS."
    condition     = var.operating_system == null || var.operating_system == "REDHAT_8_64" || var.operating_system == "RHCOS"
  }
}

variable "import_default_worker_pool_on_create" {
  type        = bool
  description = "(Advanced users) Whether to handle the default worker pool as a stand-alone ibm_container_vpc_worker_pool resource on cluster creation. Only set to false if you understand the implications of managing the default worker pool as part of the cluster resource. Set to true to import the default worker pool as a separate resource. Set to false to manage the default worker pool as part of the cluster resource."
  default     = true
  nullable    = false
}

variable "allow_default_worker_pool_replacement" {
  type        = bool
  description = "(Advanced users) Set to true to allow the module to recreate a default worker pool. Only use in the case where you are getting an error indicating that the default worker pool cannot be replaced on apply. Once the default worker pool is handled as a stand-alone ibm_container_vpc_worker_pool, if you wish to make any change to the default worker pool which requires the re-creation of the default pool set this variable to true."
  default     = false
  nullable    = false
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

variable "kms_wait_for_apply" {
  type        = bool
  description = "Set true to make terraform wait until KMS is applied to master and it is ready and deployed. Default value is true."
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

variable "attach_ibm_managed_security_group" {
  description = "Whether to attach the IBM-defined default security group (named `kube-<clusterid>`) to all worker nodes. Applies only if `custom_security_group_ids` is set."
  type        = bool
  default     = true
}

variable "custom_security_group_ids" {
  description = "Up to 4 additional security groups to add to all worker nodes. If `use_ibm_managed_security_group` is set to `true`, these security groups are in addition to the IBM-maintained security group. If additional groups are added, the default VPC security group is not assigned to the worker nodes."
  type        = list(string)
  default     = null
  validation {
    condition     = var.custom_security_group_ids == null ? true : length(var.custom_security_group_ids) <= 4
    error_message = "Please provide at most 4 additional security groups."
  }
}

##############################################################################
# Logs Agents variables
##############################################################################

variable "logs_agent_enabled" {
  type        = bool
  description = "Whether to deploy the Logs agent."
  default     = true
}

variable "logs_agent_name" {
  description = "The name of the Logs agent. The name is used in all Kubernetes and Helm resources in the cluster."
  type        = string
  default     = "logs-agent"
  nullable    = false
}

variable "logs_agent_namespace" {
  type        = string
  description = "The namespace where the Logs agent is deployed. The default value is `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "logs_agent_iam_api_key" {
  type        = string
  description = "The IBM Cloud API key for the Logs agent to authenticate and communicate with the IBM Cloud Logs. It is required if `logs_agent_iam_mode` is set to `IAMAPIKey`."
  sensitive   = true
  default     = null
}

variable "logs_agent_tolerations" {
  description = "List of tolerations to apply to Logs agent. The default value means a pod will run on every node."
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

variable "logs_agent_additional_log_source_paths" {
  type        = list(string)
  description = "The list of additional log sources. By default, the Logs agent collects logs from a single source at `/var/log/containers/*.log`."
  default     = []
  nullable    = false
}

variable "logs_agent_exclude_log_source_paths" {
  type        = list(string)
  description = "The list of log sources to exclude. Specify the paths that the Logs agent ignores."
  default     = []
  nullable    = false
}

variable "logs_agent_selected_log_source_paths" {
  type        = list(string)
  description = "The list of specific log sources paths. Logs will only be collected from the specified log source paths. If no paths are specified, it will send logs from `/var/log/containers`."
  default     = []
  nullable    = false
}

variable "logs_agent_log_source_namespaces" {
  type        = list(string)
  description = "The list of namespaces from which logs should be forwarded by agent. If namespaces are not listed, logs from all namespaces will be sent."
  default     = []
  nullable    = false
}

variable "logs_agent_iam_mode" {
  type        = string
  default     = "TrustedProfile"
  description = "IAM authentication mode: `TrustedProfile` or `IAMAPIKey`."
}

variable "logs_agent_iam_environment" {
  type        = string
  default     = "PrivateProduction"
  description = "IAM authentication Environment: `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`. `Production` specifies the public endpoint & `PrivateProduction` specifies the private endpoint."
}

variable "logs_agent_additional_metadata" {
  description = "The list of additional metadata fields to add to the routed logs."
  type = list(object({
    key   = optional(string)
    value = optional(string)
  }))
  default = []
}

variable "cloud_logs_ingress_endpoint" {
  description = "The host for IBM Cloud Logs ingestion. Ensure you use the ingress endpoint. See https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-endpoints_ingress."
  type        = string
  default     = null
}

variable "cloud_logs_ingress_port" {
  type        = number
  default     = 3443
  description = "The target port for the IBM Cloud Logs ingestion endpoint. The port must be 443 if you connect by using a VPE gateway, or port 3443 when you connect by using CSEs."
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
