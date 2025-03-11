<!-- BEGIN MODULE HOOK -->

# Red Hat OCP (OpenShift Container Platform) All Inclusive Module
<!-- UPDATE BADGE: Update the link for the following badge-->
[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![Build status](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-all-inclusive/actions/workflows/ci.yml/badge.svg)](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-all-inclusive/actions/workflows/ci.yml)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-ocp-all-inclusive?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-all-inclusive/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module is a wrapper module that groups the following modules:
- [base-ocp-vpc-module](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc) - Provisions a base (bare) Red Hat OpenShift Container Platform cluster on VPC Gen2 (supports passing Key Protect details to encrypt cluster).
- [observability-agents-module](https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents) - Deploys Logs Agent and Cloud Monitoring agents to a cluster.

:exclamation: **Important:** You can't update Red Hat OpenShift cluster nodes by using this module. The Terraform logic ignores updates to prevent possible destructive changes.

## Before you begin

- Make sure that you have a recent version of the [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started)
- Make sure that you have a recent version of the [IBM Cloud Kubernetes service CLI](https://cloud.ibm.com/docs/containers?topic=containers-kubernetes-service-cli)

### Important Considerations for Terraform and Default Worker Pool

**Changes Requiring Re-creation of Default Worker Pool**

If you need to make changes to the default worker pool that require its re-creation (e.g., changing the worker node `operating_system`), you need to follow 3 steps:
1. you must set the `allow_default_worker_pool_replacement` variable to `true`, perform the apply.
2. Once the first apply is successful, then make the required change to the default worker pool object, perform the apply.
3. After successful apply of the default worker pool change set `allow_default_worker_pool_replacement` back to `false` in the code before the subsequent apply.

This is **only** necessary for changes that require the recreation the entire default pool and is **not needed for scenarios that does not require recreating the worker pool such as changing the number of workers in the default worker pool**.

This approach is due to a limitation in the Terraform provider that may be lifted in the future.

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-ocp-all-inclusive](#terraform-ibm-ocp-all-inclusive)
* [Examples](./examples)
    * [Basic Example](./examples/basic)
    * [Private-only Example](./examples/private-only-example)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->

## terraform-ibm-ocp-all-inclusive

### Usage
```hcl
##############################################################################
# Required providers
##############################################################################

provider "ibm" {
  ibmcloud_api_key = "XXXXXXXXXX" # pragma: allowlist secret
  region           = "us-south"
}

# data lookup required to initialse helm and kubernetes providers
data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id = module.ocp_all_inclusive.cluster_id
}

provider "helm" {
  kubernetes {
    host                   = data.ibm_container_cluster_config.cluster_config.host
    token                  = data.ibm_container_cluster_config.cluster_config.token
  }
  # IBM Cloud credentials are required to authenticate to the helm repo
  registry {
    url = "oci://icr.io/ibm/observe/logs-agent-helm"
    username = "iamapikey"
    password = "XXXXXXXXXXXXXXXXX" # replace with an IBM cloud apikey # pragma: allowlist secret
  }
}

provider "kubernetes" {
  host                   = data.ibm_container_cluster_config.cluster_config.host
  token                  = data.ibm_container_cluster_config.cluster_config.token
}

##############################################################################
# ocp-all-inclusive-module
##############################################################################

module "ocp_all_inclusive" {
  source  = "terraform-ibm-modules/ocp-all-inclusive/ibm"
  version = "latest" # Replace "latest" with a release version to lock into a specific release
  ibmcloud_api_key              = "XXXXXXXXXX" # pragma: allowlist secret
  resource_group_id             = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
  region                        = "us-south"
  cluster_name                  = "my-test-cluster"
  cos_name                      = "my-cos-instance"
  vpc_id                        = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
  vpc_subnets = {
    zone-1 = [
      for zone in module.vpc.subnet_zone_list :
      {
        id         = zone.id
        zone       = zone.zone
        cidr_block = zone.cidr
      }
    ]
  }
  cloud_logs_ingress_endpoint             = "<cloud-logs-instance-guid>.ingress.us-south.logs.cloud.ibm.com"
  cloud_logs_ingress_port                 = 443
  cloud_monitoring_instance_name          = "my-sysdig"
  cloud_monitoring_access_key             = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
}
```

### Required IAM access policies
You need the following permissions to run this module.

- Account Management
    - **All Identity and Access Enabled** service
        - `Viewer` platform access
    - **All Resource Groups** service
        - `Viewer` platform access
- IAM Services
    - **Cloud Object Storage** service
        - `Editor` platform access
        - `Manager` service access
    - **Kubernetes** service
        - `Administrator` platform access
        - `Manager` service access
    - **VPC Infrastructure** service
        - `Administrator` platform access
        - `Manager` service access

<!-- END MODULE HOOK -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 2.2.3, < 3.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.8.0, < 3.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.71.0, < 2.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.16.1, < 3.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.3, < 3.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1, < 4.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1, < 1.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_observability_agents"></a> [observability\_agents](#module\_observability\_agents) | terraform-ibm-modules/observability-agents/ibm | 2.5.0 |
| <a name="module_ocp_base"></a> [ocp\_base](#module\_ocp\_base) | terraform-ibm-modules/base-ocp-vpc/ibm | 3.41.5 |
| <a name="module_trusted_profile"></a> [trusted\_profile](#module\_trusted\_profile) | terraform-ibm-modules/trusted-profile/ibm | 1.0.5 |


### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags) | Optional list of access management tags to add to the OCP Cluster created by this module. | `list(string)` | `[]` | no |
| <a name="input_additional_lb_security_group_ids"></a> [additional\_lb\_security\_group\_ids](#input\_additional\_lb\_security\_group\_ids) | Additional security group IDs to add to the load balancers associated with the cluster. These security groups are in addition to the IBM-maintained security group. | `list(string)` | `[]` | no |
| <a name="input_additional_vpe_security_group_ids"></a> [additional\_vpe\_security\_group\_ids](#input\_additional\_vpe\_security\_group\_ids) | Additional security groups to add to all the load balancers. This comes in addition to the IBM maintained security group. | <pre>object({<br/>    master   = optional(list(string), [])<br/>    registry = optional(list(string), [])<br/>    api      = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_addons"></a> [addons](#input\_addons) | List of all addons supported by the ocp cluster. | <pre>object({<br/>    debug-tool                = optional(string)<br/>    image-key-synchronizer    = optional(string)<br/>    openshift-data-foundation = optional(string)<br/>    vpc-file-csi-driver       = optional(string)<br/>    static-route              = optional(string)<br/>    cluster-autoscaler        = optional(string)<br/>    vpc-block-csi-driver      = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_allow_default_worker_pool_replacement"></a> [allow\_default\_worker\_pool\_replacement](#input\_allow\_default\_worker\_pool\_replacement) | (Advanced users) Set to true to allow the module to recreate a default worker pool. If you wish to make any change to the default worker pool which requires the re-creation of the default pool follow these [steps](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-all-inclusive?tab=readme-ov-file#important-considerations-for-terraform-and-default-worker-pool). | `bool` | `false` | no |
| <a name="input_attach_ibm_managed_security_group"></a> [attach\_ibm\_managed\_security\_group](#input\_attach\_ibm\_managed\_security\_group) | Whether to attach the IBM-defined default security group (named `kube-<clusterid>`) to all worker nodes. Applies only if `custom_security_group_ids` is set. | `bool` | `true` | no |
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | The list of context-based restriction rules to create. | <pre>list(object({<br/>    description = string<br/>    account_id  = string<br/>    rule_contexts = list(object({<br/>      attributes = optional(list(object({<br/>        name  = string<br/>        value = string<br/>    }))) }))<br/>    enforcement_mode = string<br/>    tags = optional(list(object({<br/>      name  = string<br/>      value = string<br/>    })), [])<br/>    operations = optional(list(object({<br/>      api_types = list(object({<br/>        api_type_id = string<br/>      }))<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_cloud_logs_ingress_endpoint"></a> [cloud\_logs\_ingress\_endpoint](#input\_cloud\_logs\_ingress\_endpoint) | The host for IBM Cloud Logs ingestion. It is required if `logs_agent_enabled` is set to `true`. Ensure you use the ingress endpoint. See https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-endpoints_ingress. | `string` | `null` | no |
| <a name="input_cloud_logs_ingress_port"></a> [cloud\_logs\_ingress\_port](#input\_cloud\_logs\_ingress\_port) | The target port for the IBM Cloud Logs ingestion endpoint. The port must be 443 if you connect by using a VPE gateway, or port 3443 when you connect by using CSEs. | `number` | `3443` | no |
| <a name="input_cloud_monitoring_access_key"></a> [cloud\_monitoring\_access\_key](#input\_cloud\_monitoring\_access\_key) | Access key for the Cloud Monitoring agent to communicate with the instance. | `string` | `null` | no |
| <a name="input_cloud_monitoring_add_cluster_name"></a> [cloud\_monitoring\_add\_cluster\_name](#input\_cloud\_monitoring\_add\_cluster\_name) | If true, configure the cloud monitoring agent to attach a tag containing the cluster name to all metric data. | `bool` | `true` | no |
| <a name="input_cloud_monitoring_agent_name"></a> [cloud\_monitoring\_agent\_name](#input\_cloud\_monitoring\_agent\_name) | Cloud Monitoring agent name. Used for naming all kubernetes and helm resources on the cluster. | `string` | `"sysdig-agent"` | no |
| <a name="input_cloud_monitoring_agent_namespace"></a> [cloud\_monitoring\_agent\_namespace](#input\_cloud\_monitoring\_agent\_namespace) | Namespace where to deploy the Cloud Monitoring agent. Default value is 'ibm-observe' | `string` | `"ibm-observe"` | no |
| <a name="input_cloud_monitoring_agent_tags"></a> [cloud\_monitoring\_agent\_tags](#input\_cloud\_monitoring\_agent\_tags) | List of tags to associate with the cloud monitoring agents | `list(string)` | `[]` | no |
| <a name="input_cloud_monitoring_agent_tolerations"></a> [cloud\_monitoring\_agent\_tolerations](#input\_cloud\_monitoring\_agent\_tolerations) | List of tolerations to apply to Cloud Monitoring agent. | <pre>list(object({<br/>    key               = optional(string)<br/>    operator          = optional(string)<br/>    value             = optional(string)<br/>    effect            = optional(string)<br/>    tolerationSeconds = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "operator": "Exists"<br/>  },<br/>  {<br/>    "effect": "NoSchedule",<br/>    "key": "node-role.kubernetes.io/master",<br/>    "operator": "Exists"<br/>  }<br/>]</pre> | no |
| <a name="input_cloud_monitoring_container_filter"></a> [cloud\_monitoring\_container\_filter](#input\_cloud\_monitoring\_container\_filter) | To filter custom containers, specify the Cloud Monitoring containers to include or to exclude. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_filter_data. | <pre>list(object({<br/>    type      = string<br/>    parameter = string<br/>    name      = string<br/>  }))</pre> | `[]` | no |
| <a name="input_cloud_monitoring_enabled"></a> [cloud\_monitoring\_enabled](#input\_cloud\_monitoring\_enabled) | Deploy IBM Cloud Monitoring agent | `bool` | `true` | no |
| <a name="input_cloud_monitoring_endpoint_type"></a> [cloud\_monitoring\_endpoint\_type](#input\_cloud\_monitoring\_endpoint\_type) | Specify the IBM Cloud Monitoring instance endpoint type (public or private) to use. Used to construct the ingestion endpoint. | `string` | `"private"` | no |
| <a name="input_cloud_monitoring_instance_region"></a> [cloud\_monitoring\_instance\_region](#input\_cloud\_monitoring\_instance\_region) | The IBM Cloud Monitoring instance region. Used to construct the ingestion endpoint. | `string` | `null` | no |
| <a name="input_cloud_monitoring_metrics_filter"></a> [cloud\_monitoring\_metrics\_filter](#input\_cloud\_monitoring\_metrics\_filter) | To filter custom metrics, specify the Cloud Monitoring metrics to include or to exclude. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics. | <pre>list(object({<br/>    type = string<br/>    name = string<br/>  }))</pre> | `[]` | no |
| <a name="input_cloud_monitoring_secret_name"></a> [cloud\_monitoring\_secret\_name](#input\_cloud\_monitoring\_secret\_name) | The name of the secret which will store the access key. | `string` | `"sysdig-agent"` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name to give the OCP cluster provisioned by the module. | `string` | n/a | yes |
| <a name="input_cluster_ready_when"></a> [cluster\_ready\_when](#input\_cluster\_ready\_when) | The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady | `string` | `"IngressReady"` | no |
| <a name="input_cluster_tags"></a> [cluster\_tags](#input\_cluster\_tags) | List of metadata labels to add to cluster. | `list(string)` | `[]` | no |
| <a name="input_cos_name"></a> [cos\_name](#input\_cos\_name) | Name of the COS instance to provision for OpenShift internal registry storage. New instance only provisioned if 'enable\_registry\_storage' is true and 'use\_existing\_cos' is false. Default: '<cluster\_name>\_cos' | `string` | `null` | no |
| <a name="input_custom_security_group_ids"></a> [custom\_security\_group\_ids](#input\_custom\_security\_group\_ids) | Up to 4 additional security groups to add to all worker nodes. If `use_ibm_managed_security_group` is set to `true`, these security groups are in addition to the IBM-maintained security group. If additional groups are added, the default VPC security group is not assigned to the worker nodes. | `list(string)` | `null` | no |
| <a name="input_disable_outbound_traffic_protection"></a> [disable\_outbound\_traffic\_protection](#input\_disable\_outbound\_traffic\_protection) | Whether to allow public outbound access from the cluster workers. This is only applicable for Red Hat OpenShift 4.15. | `bool` | `false` | no |
| <a name="input_disable_public_endpoint"></a> [disable\_public\_endpoint](#input\_disable\_public\_endpoint) | Whether access to the public service endpoint is disabled when the cluster is created. Does not affect existing clusters. You can't disable a public endpoint on an existing cluster, so you can't convert a public cluster to a private cluster. To change a public endpoint to private, create another cluster with this input set to `true`. | `bool` | `false` | no |
| <a name="input_enable_registry_storage"></a> [enable\_registry\_storage](#input\_enable\_registry\_storage) | Set to `true` to enable IBM Cloud Object Storage for the Red Hat OpenShift internal image registry. Set to `false` only for new cluster deployments in an account that is allowlisted for this feature. | `bool` | `true` | no |
| <a name="input_existing_cos_id"></a> [existing\_cos\_id](#input\_existing\_cos\_id) | The COS id of an already existing COS instance to use for OpenShift internal registry storage. Only required if 'enable\_registry\_storage' and 'use\_existing\_cos' are true | `string` | `null` | no |
| <a name="input_existing_kms_instance_guid"></a> [existing\_kms\_instance\_guid](#input\_existing\_kms\_instance\_guid) | The GUID of an existing KMS instance which will be used for cluster encryption. If no value passed, cluster data is stored in the Kubernetes etcd, which ends up on the local disk of the Kubernetes master (not recommended). | `string` | `null` | no |
| <a name="input_existing_kms_root_key_id"></a> [existing\_kms\_root\_key\_id](#input\_existing\_kms\_root\_key\_id) | The Key ID of a root key, existing in the KMS instance passed in var.existing\_kms\_instance\_guid, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the secrets in the cluster. Required if value passed for var.existing\_kms\_instance\_guid. | `string` | `null` | no |
| <a name="input_existing_trusted_profile_id"></a> [existing\_trusted\_profile\_id](#input\_existing\_trusted\_profile\_id) | The ID of an existing trusted profile which will be used by the Logs agent. Ensure it has the required permissions to send logs to the Cloud Logs instance. This will only be used if logs\_agent\_iam\_mode is set to TrustedProfile. If no value is passed, a new trusted profile will be created and used. | `string` | `null` | no |
| <a name="input_force_delete_storage"></a> [force\_delete\_storage](#input\_force\_delete\_storage) | Delete attached storage when destroying the cluster - Default: false | `bool` | `false` | no |
| <a name="input_ignore_worker_pool_size_changes"></a> [ignore\_worker\_pool\_size\_changes](#input\_ignore\_worker\_pool\_size\_changes) | Enable if using worker autoscaling. Stops Terraform managing worker count | `bool` | `false` | no |
| <a name="input_kms_account_id"></a> [kms\_account\_id](#input\_kms\_account\_id) | Id of the account that owns the KMS instance to encrypt the cluster. It is only required if the KMS instance is in another account. | `string` | `null` | no |
| <a name="input_kms_use_private_endpoint"></a> [kms\_use\_private\_endpoint](#input\_kms\_use\_private\_endpoint) | Set as true to use the Private endpoint when communicating between cluster and KMS instance. | `bool` | `true` | no |
| <a name="input_kms_wait_for_apply"></a> [kms\_wait\_for\_apply](#input\_kms\_wait\_for\_apply) | Set true to make terraform wait until KMS is applied to master and it is ready and deployed. Default value is true. | `bool` | `true` | no |
| <a name="input_logs_agent_additional_log_source_paths"></a> [logs\_agent\_additional\_log\_source\_paths](#input\_logs\_agent\_additional\_log\_source\_paths) | The list of additional log sources. By default, the Logs agent collects logs from a single source at `/var/log/containers/*.log`. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_additional_metadata"></a> [logs\_agent\_additional\_metadata](#input\_logs\_agent\_additional\_metadata) | The list of additional metadata fields to add to the routed logs. | <pre>list(object({<br/>    key   = optional(string)<br/>    value = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_logs_agent_enabled"></a> [logs\_agent\_enabled](#input\_logs\_agent\_enabled) | Whether to deploy the Logs agent. | `bool` | `true` | no |
| <a name="input_logs_agent_exclude_log_source_paths"></a> [logs\_agent\_exclude\_log\_source\_paths](#input\_logs\_agent\_exclude\_log\_source\_paths) | The list of log sources to exclude. Specify the paths that the Logs agent ignores. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_iam_api_key"></a> [logs\_agent\_iam\_api\_key](#input\_logs\_agent\_iam\_api\_key) | The IBM Cloud API key for the Logs agent to authenticate and communicate with the IBM Cloud Logs. It is required if `logs_agent_enabled` is true and `logs_agent_iam_mode` is set to `IAMAPIKey`. | `string` | `null` | no |
| <a name="input_logs_agent_iam_environment"></a> [logs\_agent\_iam\_environment](#input\_logs\_agent\_iam\_environment) | IAM authentication Environment: `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`. `Production` specifies the public endpoint & `PrivateProduction` specifies the private endpoint. | `string` | `"PrivateProduction"` | no |
| <a name="input_logs_agent_iam_mode"></a> [logs\_agent\_iam\_mode](#input\_logs\_agent\_iam\_mode) | IAM authentication mode: `TrustedProfile` or `IAMAPIKey`. If `TrustedProfile` is selected, the module will create one. | `string` | `"TrustedProfile"` | no |
| <a name="input_logs_agent_log_source_namespaces"></a> [logs\_agent\_log\_source\_namespaces](#input\_logs\_agent\_log\_source\_namespaces) | The list of namespaces from which logs should be forwarded by agent. If namespaces are not listed, logs from all namespaces will be sent. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_name"></a> [logs\_agent\_name](#input\_logs\_agent\_name) | The name of the Logs agent. The name is used in all Kubernetes and Helm resources in the cluster. | `string` | `"logs-agent"` | no |
| <a name="input_logs_agent_namespace"></a> [logs\_agent\_namespace](#input\_logs\_agent\_namespace) | The namespace where the Logs agent is deployed. The default value is `ibm-observe`. | `string` | `"ibm-observe"` | no |
| <a name="input_logs_agent_selected_log_source_paths"></a> [logs\_agent\_selected\_log\_source\_paths](#input\_logs\_agent\_selected\_log\_source\_paths) | The list of specific log sources paths. Logs will only be collected from the specified log source paths. If no paths are specified, it will send logs from `/var/log/containers`. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_tolerations"></a> [logs\_agent\_tolerations](#input\_logs\_agent\_tolerations) | List of tolerations to apply to Logs agent. The default value means a pod will run on every node. | <pre>list(object({<br/>    key               = optional(string)<br/>    operator          = optional(string)<br/>    value             = optional(string)<br/>    effect            = optional(string)<br/>    tolerationSeconds = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "operator": "Exists"<br/>  }<br/>]</pre> | no |
| <a name="input_manage_all_addons"></a> [manage\_all\_addons](#input\_manage\_all\_addons) | Whether Terraform manages all cluster add-ons, even add-ons installed outside of the module. If set to 'true', this module destroys the add-ons installed by other sources. | `bool` | `false` | no |
| <a name="input_number_of_lbs"></a> [number\_of\_lbs](#input\_number\_of\_lbs) | The number of load balancer to associate with the `additional_lb_security_group_names` security group. Must match the number of load balancers that are associated with the cluster | `number` | `1` | no |
| <a name="input_ocp_entitlement"></a> [ocp\_entitlement](#input\_ocp\_entitlement) | Value that is applied to the entitlements for OCP cluster provisioning | `string` | `"cloud_pak"` | no |
| <a name="input_ocp_version"></a> [ocp\_version](#input\_ocp\_version) | The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. Supports passing the string 'default' (current IKS default recommended version). If no value is passed, it will default to 'default'. | `string` | `null` | no |
| <a name="input_pod_subnet_cidr"></a> [pod\_subnet\_cidr](#input\_pod\_subnet\_cidr) | Specify a custom subnet CIDR to provide private IP addresses for pods. The subnet must have a CIDR of at least `/23` or larger. Default value is `172.30.0.0/16` when the variable is set to `null`. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where all resources will be provisioned. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The IBM Cloud resource group ID to provision all resources in. | `string` | n/a | yes |
| <a name="input_service_subnet_cidr"></a> [service\_subnet\_cidr](#input\_service\_subnet\_cidr) | Specify a custom subnet CIDR to provide private IP addresses for services. The subnet must be at least `/24` or larger. Default value is `172.21.0.0/16` when the variable is set to `null`. | `string` | `null` | no |
| <a name="input_use_existing_cos"></a> [use\_existing\_cos](#input\_use\_existing\_cos) | Flag indicating whether or not to use an existing COS instance for OpenShift internal registry storage. Only applicable if 'enable\_registry\_storage' is true | `bool` | `false` | no |
| <a name="input_use_private_endpoint"></a> [use\_private\_endpoint](#input\_use\_private\_endpoint) | Set this to true to force all api calls to use the IBM Cloud private endpoints. | `bool` | `false` | no |
| <a name="input_verify_worker_network_readiness"></a> [verify\_worker\_network\_readiness](#input\_verify\_worker\_network\_readiness) | By setting this to true, a script will run kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, this should be set to false. | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to use. | `string` | n/a | yes |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | Subnet metadata by VPC tier. | <pre>map(list(object({<br/>    id         = string<br/>    zone       = string<br/>    cidr_block = string<br/>  })))</pre> | n/a | yes |
| <a name="input_worker_pools"></a> [worker\_pools](#input\_worker\_pools) | List of worker pools | <pre>list(object({<br/>    subnet_prefix = optional(string)<br/>    vpc_subnets = optional(list(object({<br/>      id         = string<br/>      zone       = string<br/>      cidr_block = string<br/>    })))<br/>    pool_name         = string<br/>    machine_type      = string<br/>    workers_per_zone  = number<br/>    resource_group_id = optional(string)<br/>    operating_system  = string<br/>    labels            = optional(map(string))<br/>    minSize           = optional(number)<br/>    secondary_storage = optional(string)<br/>    maxSize           = optional(number)<br/>    enableAutoscaling = optional(bool)<br/>    boot_volume_encryption_kms_config = optional(object({<br/>      crk             = string<br/>      kms_instance_id = string<br/>      kms_account_id  = optional(string)<br/>    }))<br/>    additional_security_group_ids = optional(list(string))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "enableAutoscaling": true,<br/>    "labels": {},<br/>    "machine_type": "bx2.4x16",<br/>    "maxSize": 3,<br/>    "minSize": 1,<br/>    "operating_system": "REDHAT_8_64",<br/>    "pool_name": "default",<br/>    "subnet_prefix": "zone-1",<br/>    "workers_per_zone": 2<br/>  },<br/>  {<br/>    "enableAutoscaling": true,<br/>    "labels": {<br/>      "dedicated": "zone-2"<br/>    },<br/>    "machine_type": "bx2.4x16",<br/>    "maxSize": 3,<br/>    "minSize": 1,<br/>    "operating_system": "REDHAT_8_64",<br/>    "pool_name": "zone-2",<br/>    "subnet_prefix": "zone-2",<br/>    "workers_per_zone": 2<br/>  },<br/>  {<br/>    "enableAutoscaling": true,<br/>    "labels": {<br/>      "dedicated": "zone-3"<br/>    },<br/>    "machine_type": "bx2.4x16",<br/>    "maxSize": 3,<br/>    "minSize": 1,<br/>    "operating_system": "REDHAT_8_64",<br/>    "pool_name": "zone-3",<br/>    "subnet_prefix": "zone-3",<br/>    "workers_per_zone": 2<br/>  }<br/>]</pre> | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_crn"></a> [cluster\_crn](#output\_cluster\_crn) | CRN for the created cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of cluster created |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the created cluster |
| <a name="output_cos_crn"></a> [cos\_crn](#output\_cos\_crn) | The IBM Cloud Object Storage instance CRN used to back up the internal registry in the OCP cluster. |
| <a name="output_ingress_hostname"></a> [ingress\_hostname](#output\_ingress\_hostname) | The hostname that was assigned to the OCP clusters Ingress subdomain. |
| <a name="output_master_url"></a> [master\_url](#output\_master\_url) | The URL of the Kubernetes master. |
| <a name="output_ocp_version"></a> [ocp\_version](#output\_ocp\_version) | Openshift Version of the cluster |
| <a name="output_private_service_endpoint_url"></a> [private\_service\_endpoint\_url](#output\_private\_service\_endpoint\_url) | Private service endpoint URL |
| <a name="output_public_service_endpoint_url"></a> [public\_service\_endpoint\_url](#output\_public\_service\_endpoint\_url) | Public service endpoint URL |
| <a name="output_region"></a> [region](#output\_region) | Region cluster is deployed in |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | Resource group ID the cluster is deployed in |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the clusters VPC |
| <a name="output_vpe_url"></a> [vpe\_url](#output\_vpe\_url) | The virtual private endpoint URL of the Kubernetes cluster. |
| <a name="output_workerpools"></a> [workerpools](#output\_workerpools) | Worker pools created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- BEGIN CONTRIBUTING HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
<!-- Source for this readme file: https://github.com/terraform-ibm-modules/common-dev-assets/tree/main/module-assets/ci/module-template-automation -->
<!-- END CONTRIBUTING HOOK -->
