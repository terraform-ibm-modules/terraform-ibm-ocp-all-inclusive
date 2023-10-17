variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Token"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Prefix for all provisioned resources"
  default     = "goldeneye-test"
}

variable "region" {
  type        = string
  description = "Region to provision all resources created by this example"
  default     = "au-syd"
}

variable "ocp_version" {
  description = "The version of the OpenShift cluster that should be provisioned (format 4.x)"
  type        = string
  default     = null
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "Optional list of access management tags to add to the OCP Cluster created by this module."
  default     = []
}

variable "worker_pools" {
  type = list(object({
    subnet_prefix     = string
    pool_name         = string
    machine_type      = string
    workers_per_zone  = number
    resource_group_id = optional(string)
    labels            = optional(map(string))
  }))
  default = [
    {
      subnet_prefix     = "zone-1"
      pool_name         = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type      = "bx2.4x16"
      workers_per_zone  = 3
      minSize           = 1
      maxSize           = 5
      enableAutoscaling = true
      labels            = {}
    }
  ]
  description = "List of worker pools"
}

variable "disable_public_endpoint" {
  type        = bool
  description = "Flag indicating that the public endpoint should be disabled"
  default     = false
}

variable "logdna_agent_tags" {
  type        = list(string)
  description = "array of tags to group the host logs pushed by the logdna agent"
  default     = []
}
