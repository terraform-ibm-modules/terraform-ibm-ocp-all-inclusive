<!-- BEGIN MODULE HOOK -->

<!-- Update the title to match the module name and add a description -->
# Red Hat OCP (OpenShift Container Platform) All Inclusive Module
<!-- UPDATE BADGE: Update the link for the following badge-->
[![Incubating (Not yet consumable)](https://img.shields.io/badge/status-Incubating%20(Not%20yet%20consumable)-red)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![Build status](https://github.com/terraform-ibm-modules/terraform-ibm-module-template/actions/workflows/ci.yml/badge.svg)](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-all-inclusive/actions/workflows/ci.yml)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-module-template?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-all-inclusive/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module is a wrapper module that groups the following modules:
- [base-ocp-vpc-module](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc) - Provisions a base (bare) Red Hat OpenShift Container Platform cluster on VPC Gen2 (supports passing Key Protect details to encrypt cluster).
- [observability-agents-module](https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents) - Deploys LogDNA and Sysdig agents to a cluster.

:exclamation: **Important:** You can't update Red Hat OpenShift cluster nodes by using this module. The Terraform logic ignores updates to prevent possible destructive changes.

## Before you begin

- Make sure that you have a recent version of the [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started)
- Make sure that you have a recent version of the [IBM Cloud Kubernetes service CLI](https://cloud.ibm.com/docs/containers?topic=containers-kubernetes-service-cli)

## Usage
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
  # Replace "master" with a GIT release version to lock into a specific release
  source                        = "git::https://github.com/terraform-ibm-modules/terraform-ibm-ocp-all-inclusive.git?ref=master"
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
  logdna_instance_name          = "my-logdna"
  logdna_ingestion_key          = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
  sysdig_instance_name          = "my-sysdig"
  sysdig_access_key             = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
}
```

## Required IAM access policies
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
<!-- BEGIN EXAMPLES HOOK -->
## Examples

- [ Complete Example](examples/end-to-end-example)
<!-- END EXAMPLES HOOK -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 2.2.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.8.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.49.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.16.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.3 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_observability_agents"></a> [observability\_agents](#module\_observability\_agents) | git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents | v1.0.0 |
| <a name="module_ocp_base"></a> [ocp\_base](#module\_ocp\_base) | git::https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc.git | v1.0.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name to give the OCP cluster provisioned by the module. | `string` | n/a | yes |
| <a name="input_cluster_ready_when"></a> [cluster\_ready\_when](#input\_cluster\_ready\_when) | The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady | `string` | `"IngressReady"` | no |
| <a name="input_cluster_tags"></a> [cluster\_tags](#input\_cluster\_tags) | List of metadata labels to add to cluster. | `list(string)` | `[]` | no |
| <a name="input_cos_name"></a> [cos\_name](#input\_cos\_name) | The name to give the COS instance that will be provisioned by this module if var.use\_existing\_cos is false. COS is required to back up the OpenShift internal registry. | `string` | `null` | no |
| <a name="input_disable_public_endpoint"></a> [disable\_public\_endpoint](#input\_disable\_public\_endpoint) | Flag indicating that the public endpoint should be disabled | `bool` | `false` | no |
| <a name="input_existing_cos_id"></a> [existing\_cos\_id](#input\_existing\_cos\_id) | The COS ID of an already existing COS instance which will be used to back up the OpenShift internal registry. Required if var.use\_existing\_cos is true. | `string` | `null` | no |
| <a name="input_existing_key_protect_instance_guid"></a> [existing\_key\_protect\_instance\_guid](#input\_existing\_key\_protect\_instance\_guid) | The GUID of an existing Key Protect instance which will be used for cluster encryption. If no value passed, cluster data is stored in the Kubernetes etcd, which ends up on the local disk of the Kubernetes master (not recommended). | `string` | `null` | no |
| <a name="input_existing_key_protect_root_key_id"></a> [existing\_key\_protect\_root\_key\_id](#input\_existing\_key\_protect\_root\_key\_id) | The Key ID of a root key, existing in the Key Protect instance passed in var.existing\_key\_protect\_instance\_guid, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the secrets in the cluster. Required if value passed for var.existing\_key\_protect\_instance\_guid. | `string` | `null` | no |
| <a name="input_force_delete_storage"></a> [force\_delete\_storage](#input\_force\_delete\_storage) | Delete attached storage when destroying the cluster - Default: false | `bool` | `false` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | An IBM Cloud API key with permissions to provision resources. | `string` | n/a | yes |
| <a name="input_ignore_worker_pool_size_changes"></a> [ignore\_worker\_pool\_size\_changes](#input\_ignore\_worker\_pool\_size\_changes) | Enable if using worker autoscaling. Stops Terraform managing worker count | `bool` | `false` | no |
| <a name="input_key_protect_use_private_endpoint"></a> [key\_protect\_use\_private\_endpoint](#input\_key\_protect\_use\_private\_endpoint) | Set as true to use the Private endpoint when communicating between cluster and Key Protect Instance. | `bool` | `true` | no |
| <a name="input_logdna_agent_version"></a> [logdna\_agent\_version](#input\_logdna\_agent\_version) | Optionally override the default LogDNA agent version. If the value is null, this version is set to the version of 'logdna\_agent\_version' variable in the Observability agents module. To list available versions, run: `ibmcloud cr images --restrict ext/logdna-agent`. | `string` | `null` | no |
| <a name="input_logdna_ingestion_key"></a> [logdna\_ingestion\_key](#input\_logdna\_ingestion\_key) | Ingestion key for the LogDNA agent to communicate with the instance. | `string` | `null` | no |
| <a name="input_logdna_instance_name"></a> [logdna\_instance\_name](#input\_logdna\_instance\_name) | The name of the LogDNA instance to point the LogDNA agent to. If left at null, no agent will be deployed. | `string` | `null` | no |
| <a name="input_logdna_resource_group_id"></a> [logdna\_resource\_group\_id](#input\_logdna\_resource\_group\_id) | Resource group id that the LogDNA instance is in. If left at null, the value of var.resource\_group\_id will be used. | `string` | `null` | no |
| <a name="input_ocp_entitlement"></a> [ocp\_entitlement](#input\_ocp\_entitlement) | Value that is applied to the entitlements for OCP cluster provisioning | `string` | `"cloud_pak"` | no |
| <a name="input_ocp_version"></a> [ocp\_version](#input\_ocp\_version) | The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. If no value is passed, or the string 'default' is passed, the current default OCP version will be used. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where all resources will be provisioned. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The IBM Cloud resource group ID to provision all resources in. | `string` | n/a | yes |
| <a name="input_sysdig_access_key"></a> [sysdig\_access\_key](#input\_sysdig\_access\_key) | Access key for the Sysdig agent to communicate with the instance. | `string` | `null` | no |
| <a name="input_sysdig_agent_version"></a> [sysdig\_agent\_version](#input\_sysdig\_agent\_version) | Optionally override the default Sysdig agent version. If the value is null, this version is set to the version of 'sysdig\_agent\_version' variable in the Observability agents module. To list available versions, run: `ibmcloud cr images --restrict ext/sysdig/agent`. | `string` | `null` | no |
| <a name="input_sysdig_instance_name"></a> [sysdig\_instance\_name](#input\_sysdig\_instance\_name) | The name of the Sysdig instance to point the Sysdig agent to. If left at null, no agent will be deployed. | `string` | `null` | no |
| <a name="input_sysdig_resource_group_id"></a> [sysdig\_resource\_group\_id](#input\_sysdig\_resource\_group\_id) | Resource group id that the Sysdig instance is in. If left at null, the value of var.resource\_group\_id will be used. | `string` | `null` | no |
| <a name="input_use_existing_cos"></a> [use\_existing\_cos](#input\_use\_existing\_cos) | COS is required to back up the OpenShift internal registry. Set this to true and pass a value for var.existing\_cos\_id if you want to use an existing COS instance. | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to use. | `string` | n/a | yes |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | Subnet metadata by VPC tier. | <pre>map(list(object({<br>    id         = string<br>    zone       = string<br>    cidr_block = string<br>  })))</pre> | n/a | yes |
| <a name="input_worker_pools"></a> [worker\_pools](#input\_worker\_pools) | List of worker pools | <pre>list(object({<br>    subnet_prefix     = string<br>    pool_name         = string<br>    machine_type      = string<br>    workers_per_zone  = number<br>    resource_group_id = optional(string)<br>    labels            = optional(map(string))<br>  }))</pre> | <pre>[<br>  {<br>    "labels": {},<br>    "machine_type": "bx2.4x16",<br>    "pool_name": "default",<br>    "subnet_prefix": "zone-1",<br>    "workers_per_zone": 2<br>  },<br>  {<br>    "labels": {<br>      "dedicated": "zone-2"<br>    },<br>    "machine_type": "bx2.4x16",<br>    "pool_name": "zone-2",<br>    "subnet_prefix": "zone-2",<br>    "workers_per_zone": 2<br>  },<br>  {<br>    "labels": {<br>      "dedicated": "zone-3"<br>    },<br>    "machine_type": "bx2.4x16",<br>    "pool_name": "zone-3",<br>    "subnet_prefix": "zone-3",<br>    "workers_per_zone": 2<br>  }<br>]</pre> | no |

## Outputs

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
