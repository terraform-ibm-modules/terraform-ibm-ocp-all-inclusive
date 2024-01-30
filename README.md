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
- [observability-agents-module](https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents) - Deploys Log Analysis and Cloud Monitoring agents to a cluster.

:exclamation: **Important:** You can't update Red Hat OpenShift cluster nodes by using this module. The Terraform logic ignores updates to prevent possible destructive changes.

## Before you begin

- Make sure that you have a recent version of the [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started)
- Make sure that you have a recent version of the [IBM Cloud Kubernetes service CLI](https://cloud.ibm.com/docs/containers?topic=containers-kubernetes-service-cli)

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-ocp-all-inclusive](#terraform-ibm-ocp-all-inclusive)
* [Examples](./examples)
    * [Complete Example](./examples/end-to-end-example)
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
  log_analysis_instance_name          = "my-logdna"
  log_analysis_ingestion_key          = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, <1.6.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 2.2.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.8.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.60.0, < 2.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.16.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.3 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_observability_agents"></a> [observability\_agents](#module\_observability\_agents) | terraform-ibm-modules/observability-agents/ibm | 1.19.0 |
| <a name="module_ocp_base"></a> [ocp\_base](#module\_ocp\_base) | terraform-ibm-modules/base-ocp-vpc/ibm | 3.14.4 |

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags) | Optional list of access management tags to add to the OCP Cluster created by this module. | `list(string)` | `[]` | no |
| <a name="input_addons"></a> [addons](#input\_addons) | List of all addons supported by the ocp cluster. | <pre>object({<br>    debug-tool                = optional(string)<br>    image-key-synchronizer    = optional(string)<br>    openshift-data-foundation = optional(string)<br>    vpc-file-csi-driver       = optional(string)<br>    static-route              = optional(string)<br>    cluster-autoscaler        = optional(string)<br>    vpc-block-csi-driver      = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_cloud_monitoring_access_key"></a> [cloud\_monitoring\_access\_key](#input\_cloud\_monitoring\_access\_key) | Access key for the Cloud Monitoring agent to communicate with the instance. | `string` | `null` | no |
| <a name="input_cloud_monitoring_add_cluster_name"></a> [cloud\_monitoring\_add\_cluster\_name](#input\_cloud\_monitoring\_add\_cluster\_name) | If true, configure the cloud monitoring agent to attach a tag containing the cluster name to all metric data. | `bool` | `true` | no |
| <a name="input_cloud_monitoring_agent_name"></a> [cloud\_monitoring\_agent\_name](#input\_cloud\_monitoring\_agent\_name) | Cloud Monitoring agent name. Used for naming all kubernetes and helm resources on the cluster. | `string` | `"sysdig-agent"` | no |
| <a name="input_cloud_monitoring_agent_namespace"></a> [cloud\_monitoring\_agent\_namespace](#input\_cloud\_monitoring\_agent\_namespace) | Namespace where to deploy the Cloud Monitoring agent. Default value is 'ibm-observe' | `string` | `"ibm-observe"` | no |
| <a name="input_cloud_monitoring_agent_tags"></a> [cloud\_monitoring\_agent\_tags](#input\_cloud\_monitoring\_agent\_tags) | List of tags to associate with the cloud monitoring agents | `list(string)` | `[]` | no |
| <a name="input_cloud_monitoring_agent_tolerations"></a> [cloud\_monitoring\_agent\_tolerations](#input\_cloud\_monitoring\_agent\_tolerations) | List of tolerations to apply to Cloud Monitoring agent. | <pre>list(object({<br>    key               = optional(string)<br>    operator          = optional(string)<br>    value             = optional(string)<br>    effect            = optional(string)<br>    tolerationSeconds = optional(number)<br>  }))</pre> | <pre>[<br>  {<br>    "operator": "Exists"<br>  },<br>  {<br>    "effect": "NoSchedule",<br>    "key": "node-role.kubernetes.io/master",<br>    "operator": "Exists"<br>  }<br>]</pre> | no |
| <a name="input_cloud_monitoring_enabled"></a> [cloud\_monitoring\_enabled](#input\_cloud\_monitoring\_enabled) | Deploy IBM Cloud Monitoring agent | `bool` | `true` | no |
| <a name="input_cloud_monitoring_endpoint_type"></a> [cloud\_monitoring\_endpoint\_type](#input\_cloud\_monitoring\_endpoint\_type) | Specify the IBM Cloud Monitoring instance endpoint type (public or private) to use. Used to construct the ingestion endpoint. | `string` | `"private"` | no |
| <a name="input_cloud_monitoring_instance_region"></a> [cloud\_monitoring\_instance\_region](#input\_cloud\_monitoring\_instance\_region) | The IBM Cloud Monitoring instance region. Used to construct the ingestion endpoint. | `string` | `null` | no |
| <a name="input_cloud_monitoring_metrics_filter"></a> [cloud\_monitoring\_metrics\_filter](#input\_cloud\_monitoring\_metrics\_filter) | To filter custom metrics, specify the Cloud Monitoring metrics to include or to exclude. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics. | <pre>list(object({<br>    type = string<br>    name = string<br>  }))</pre> | `[]` | no |
| <a name="input_cloud_monitoring_secret_name"></a> [cloud\_monitoring\_secret\_name](#input\_cloud\_monitoring\_secret\_name) | The name of the secret which will store the access key. | `string` | `"sysdig-agent"` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name to give the OCP cluster provisioned by the module. | `string` | n/a | yes |
| <a name="input_cluster_ready_when"></a> [cluster\_ready\_when](#input\_cluster\_ready\_when) | The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady | `string` | `"IngressReady"` | no |
| <a name="input_cluster_tags"></a> [cluster\_tags](#input\_cluster\_tags) | List of metadata labels to add to cluster. | `list(string)` | `[]` | no |
| <a name="input_cos_name"></a> [cos\_name](#input\_cos\_name) | Name of the COS instance to provision for OpenShift internal registry storage. New instance only provisioned if 'enable\_registry\_storage' is true and 'use\_existing\_cos' is false. Default: '<cluster\_name>\_cos' | `string` | `null` | no |
| <a name="input_disable_public_endpoint"></a> [disable\_public\_endpoint](#input\_disable\_public\_endpoint) | Whether access to the public service endpoint is disabled when the cluster is created. Does not affect existing clusters. To change a public endpoint to private, create another cluster with the variable set to true or see [Switching to the private endpoint](https://cloud.ibm.com/docs/containers?topic=containers-cs_network_cluster#migrate-to-private-se). | `bool` | `false` | no |
| <a name="input_enable_registry_storage"></a> [enable\_registry\_storage](#input\_enable\_registry\_storage) | Set to `true` to enable IBM Cloud Object Storage for the Red Hat OpenShift internal image registry. Set to `false` only for new cluster deployments in an account that is allowlisted for this feature. | `bool` | `true` | no |
| <a name="input_existing_cos_id"></a> [existing\_cos\_id](#input\_existing\_cos\_id) | The COS id of an already existing COS instance to use for OpenShift internal registry storage. Only required if 'enable\_registry\_storage' and 'use\_existing\_cos' are true | `string` | `null` | no |
| <a name="input_existing_kms_instance_guid"></a> [existing\_kms\_instance\_guid](#input\_existing\_kms\_instance\_guid) | The GUID of an existing KMS instance which will be used for cluster encryption. If no value passed, cluster data is stored in the Kubernetes etcd, which ends up on the local disk of the Kubernetes master (not recommended). | `string` | `null` | no |
| <a name="input_existing_kms_root_key_id"></a> [existing\_kms\_root\_key\_id](#input\_existing\_kms\_root\_key\_id) | The Key ID of a root key, existing in the KMS instance passed in var.existing\_kms\_instance\_guid, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the secrets in the cluster. Required if value passed for var.existing\_kms\_instance\_guid. | `string` | `null` | no |
| <a name="input_force_delete_storage"></a> [force\_delete\_storage](#input\_force\_delete\_storage) | Delete attached storage when destroying the cluster - Default: false | `bool` | `false` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | An IBM Cloud API key with permissions to provision resources. | `string` | n/a | yes |
| <a name="input_ignore_worker_pool_size_changes"></a> [ignore\_worker\_pool\_size\_changes](#input\_ignore\_worker\_pool\_size\_changes) | Enable if using worker autoscaling. Stops Terraform managing worker count | `bool` | `false` | no |
| <a name="input_kms_account_id"></a> [kms\_account\_id](#input\_kms\_account\_id) | Id of the account that owns the KMS instance to encrypt the cluster. It is only required if the KMS instance is in another account. | `string` | `null` | no |
| <a name="input_kms_use_private_endpoint"></a> [kms\_use\_private\_endpoint](#input\_kms\_use\_private\_endpoint) | Set as true to use the Private endpoint when communicating between cluster and KMS instance. | `bool` | `true` | no |
| <a name="input_log_analysis_add_cluster_name"></a> [log\_analysis\_add\_cluster\_name](#input\_log\_analysis\_add\_cluster\_name) | If true, configure the log analysis agent to attach a tag containing the cluster name to all log messages. | `bool` | `true` | no |
| <a name="input_log_analysis_agent_custom_line_exclusion"></a> [log\_analysis\_agent\_custom\_line\_exclusion](#input\_log\_analysis\_agent\_custom\_line\_exclusion) | Log Analysis agent custom configuration for line exclusion setting LOGDNA\_K8S\_METADATA\_LINE\_EXCLUSION. See https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering for more info. | `string` | `null` | no |
| <a name="input_log_analysis_agent_custom_line_inclusion"></a> [log\_analysis\_agent\_custom\_line\_inclusion](#input\_log\_analysis\_agent\_custom\_line\_inclusion) | Log Analysis agent custom configuration for line inclusion setting LOGDNA\_K8S\_METADATA\_LINE\_INCLUSION. See https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering for more info. | `string` | `null` | no |
| <a name="input_log_analysis_agent_name"></a> [log\_analysis\_agent\_name](#input\_log\_analysis\_agent\_name) | Log Analysis agent name. Used for naming all kubernetes and helm resources on the cluster. | `string` | `"logdna-agent"` | no |
| <a name="input_log_analysis_agent_namespace"></a> [log\_analysis\_agent\_namespace](#input\_log\_analysis\_agent\_namespace) | Namespace where to deploy the Log Analysis agent. Default value is 'ibm-observe' | `string` | `"ibm-observe"` | no |
| <a name="input_log_analysis_agent_tags"></a> [log\_analysis\_agent\_tags](#input\_log\_analysis\_agent\_tags) | List of tags to associate with the log analysis agents | `list(string)` | `[]` | no |
| <a name="input_log_analysis_agent_tolerations"></a> [log\_analysis\_agent\_tolerations](#input\_log\_analysis\_agent\_tolerations) | List of tolerations to apply to Log Analysis agent. | <pre>list(object({<br>    key               = optional(string)<br>    operator          = optional(string)<br>    value             = optional(string)<br>    effect            = optional(string)<br>    tolerationSeconds = optional(number)<br>  }))</pre> | <pre>[<br>  {<br>    "operator": "Exists"<br>  }<br>]</pre> | no |
| <a name="input_log_analysis_enabled"></a> [log\_analysis\_enabled](#input\_log\_analysis\_enabled) | Deploy IBM Cloud Logging agent | `bool` | `true` | no |
| <a name="input_log_analysis_endpoint_type"></a> [log\_analysis\_endpoint\_type](#input\_log\_analysis\_endpoint\_type) | Specify the IBM Log Analysis instance endpoint type (public or private) to use. Used to construct the ingestion endpoint. | `string` | `"private"` | no |
| <a name="input_log_analysis_ingestion_key"></a> [log\_analysis\_ingestion\_key](#input\_log\_analysis\_ingestion\_key) | Ingestion key for the Log Analysis agent to communicate with the instance. | `string` | `null` | no |
| <a name="input_log_analysis_instance_region"></a> [log\_analysis\_instance\_region](#input\_log\_analysis\_instance\_region) | The IBM Log Analysis instance region. Used to construct the ingestion endpoint. | `string` | `null` | no |
| <a name="input_log_analysis_secret_name"></a> [log\_analysis\_secret\_name](#input\_log\_analysis\_secret\_name) | The name of the secret which will store the ingestion key. | `string` | `"logdna-agent"` | no |
| <a name="input_manage_all_addons"></a> [manage\_all\_addons](#input\_manage\_all\_addons) | Instructs Terraform to manage all cluster addons, even if addons were installed outside of the module. If set to 'true' this module will destroy any addons that were installed by other sources. | `bool` | `false` | no |
| <a name="input_ocp_entitlement"></a> [ocp\_entitlement](#input\_ocp\_entitlement) | Value that is applied to the entitlements for OCP cluster provisioning | `string` | `"cloud_pak"` | no |
| <a name="input_ocp_version"></a> [ocp\_version](#input\_ocp\_version) | The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. Supports passing the string 'default' (current IKS default recommended version). If no value is passed, it will default to 'default'. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where all resources will be provisioned. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The IBM Cloud resource group ID to provision all resources in. | `string` | n/a | yes |
| <a name="input_use_existing_cos"></a> [use\_existing\_cos](#input\_use\_existing\_cos) | Flag indicating whether or not to use an existing COS instance for OpenShift internal registry storage. Only applicable if 'enable\_registry\_storage' is true | `bool` | `false` | no |
| <a name="input_verify_worker_network_readiness"></a> [verify\_worker\_network\_readiness](#input\_verify\_worker\_network\_readiness) | By setting this to true, a script will run kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, this should be set to false. | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to use. | `string` | n/a | yes |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | Subnet metadata by VPC tier. | <pre>map(list(object({<br>    id         = string<br>    zone       = string<br>    cidr_block = string<br>  })))</pre> | n/a | yes |
| <a name="input_worker_pools"></a> [worker\_pools](#input\_worker\_pools) | List of worker pools | <pre>list(object({<br>    subnet_prefix = optional(string)<br>    vpc_subnets = optional(list(object({<br>      id         = string<br>      zone       = string<br>      cidr_block = string<br>    })))<br>    pool_name         = string<br>    machine_type      = string<br>    workers_per_zone  = number<br>    resource_group_id = optional(string)<br>    labels            = optional(map(string))<br>    minSize           = optional(number)<br>    maxSize           = optional(number)<br>    enableAutoscaling = optional(bool)<br>    boot_volume_encryption_kms_config = optional(object({<br>      crk             = string<br>      kms_instance_id = string<br>      kms_account_id  = optional(string)<br>    }))<br>  }))</pre> | <pre>[<br>  {<br>    "enableAutoscaling": true,<br>    "labels": {},<br>    "machine_type": "bx2.4x16",<br>    "maxSize": 3,<br>    "minSize": 1,<br>    "pool_name": "default",<br>    "subnet_prefix": "zone-1",<br>    "workers_per_zone": 2<br>  },<br>  {<br>    "enableAutoscaling": true,<br>    "labels": {<br>      "dedicated": "zone-2"<br>    },<br>    "machine_type": "bx2.4x16",<br>    "maxSize": 3,<br>    "minSize": 1,<br>    "pool_name": "zone-2",<br>    "subnet_prefix": "zone-2",<br>    "workers_per_zone": 2<br>  },<br>  {<br>    "enableAutoscaling": true,<br>    "labels": {<br>      "dedicated": "zone-3"<br>    },<br>    "machine_type": "bx2.4x16",<br>    "maxSize": 3,<br>    "minSize": 1,<br>    "pool_name": "zone-3",<br>    "subnet_prefix": "zone-3",<br>    "workers_per_zone": 2<br>  }<br>]</pre> | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_crn"></a> [cluster\_crn](#output\_cluster\_crn) | CRN for the created cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of cluster created |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the created cluster |
| <a name="output_cos_crn"></a> [cos\_crn](#output\_cos\_crn) | The IBM Cloud Object Storage instance CRN used to back up the internal registry in the OCP cluster. |
| <a name="output_ingress_hostname"></a> [ingress\_hostname](#output\_ingress\_hostname) | The hostname that was assigned to the OCP clusters Ingress subdomain. |
| <a name="output_ocp_version"></a> [ocp\_version](#output\_ocp\_version) | Openshift Version of the cluster |
| <a name="output_private_service_endpoint_url"></a> [private\_service\_endpoint\_url](#output\_private\_service\_endpoint\_url) | Private service endpoint URL |
| <a name="output_public_service_endpoint_url"></a> [public\_service\_endpoint\_url](#output\_public\_service\_endpoint\_url) | Public service endpoint URL |
| <a name="output_region"></a> [region](#output\_region) | Region cluster is deployed in |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | Resource group ID the cluster is deployed in |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the clusters VPC |
| <a name="output_workerpools"></a> [workerpools](#output\_workerpools) | Worker pools created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- BEGIN CONTRIBUTING HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
<!-- Source for this readme file: https://github.com/terraform-ibm-modules/common-dev-assets/tree/main/module-assets/ci/module-template-automation -->
<!-- END CONTRIBUTING HOOK -->
