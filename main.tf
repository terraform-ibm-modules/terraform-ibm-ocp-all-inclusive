##############################################################################
# base-ocp-vpc-module
##############################################################################

locals {
  # Input variable validation
  # tflint-ignore: terraform_unused_declarations
  validate_cos_inputs = (var.use_existing_cos == false && var.cos_name == null) ? tobool("A value must be passed for var.cos_name if var.use_existing_cos is false.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_existing_cos_inputs = (var.use_existing_cos == true && var.existing_cos_id == null) ? tobool("A value must be passed for var.existing_cos_id if var.use_existing_cos is true.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kp_inputs = (var.existing_kms_instance_guid == null && var.existing_kms_root_key_id != null) || (var.existing_kms_root_key_id != null && var.existing_kms_instance_guid == null) ? tobool("To enable encryption, values must be passed for both var.existing_kms_instance_guid and var.existing_kms_root_key_id. Set them both to null to create cluster without encryption (not recommended).") : true

  # If encryption enabled generate kms config to be passed to cluster
  kms_config = var.existing_kms_instance_guid != null && var.existing_kms_root_key_id != null ? {
    crk_id           = var.existing_kms_root_key_id
    instance_id      = var.existing_kms_instance_guid
    private_endpoint = var.kms_use_private_endpoint
    account_id       = var.kms_account_id
  } : null
}

module "ocp_base" {
  source                          = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                         = "3.14.0"
  cluster_name                    = var.cluster_name
  ocp_version                     = var.ocp_version
  resource_group_id               = var.resource_group_id
  region                          = var.region
  tags                            = var.cluster_tags
  access_tags                     = var.access_tags
  force_delete_storage            = var.force_delete_storage
  vpc_id                          = var.vpc_id
  vpc_subnets                     = var.vpc_subnets
  worker_pools                    = var.worker_pools
  cluster_ready_when              = var.cluster_ready_when
  cos_name                        = var.cos_name
  use_existing_cos                = var.use_existing_cos
  existing_cos_id                 = var.existing_cos_id
  ocp_entitlement                 = var.ocp_entitlement
  disable_public_endpoint         = var.disable_public_endpoint
  ignore_worker_pool_size_changes = var.ignore_worker_pool_size_changes
  kms_config                      = local.kms_config
  ibmcloud_api_key                = var.ibmcloud_api_key
  addons                          = var.addons
  manage_all_addons               = var.manage_all_addons
  verify_worker_network_readiness = var.verify_worker_network_readiness
  cluster_config_endpoint_type    = var.cluster_config_endpoint_type
  enable_registry_storage         = var.enable_registry_storage
}

##############################################################################
# observability-agents-module
##############################################################################

locals {
  # Locals
  run_observability_agents_module    = (local.provision_log_analysis_agent == true || local.provision_cloud_monitoring_agent) ? true : false
  provision_log_analysis_agent       = var.log_analysis_instance_name != null ? true : false
  provision_cloud_monitoring_agent   = var.cloud_monitoring_instance_name != null ? true : false
  log_analysis_resource_group_id     = var.log_analysis_resource_group_id != null ? var.log_analysis_resource_group_id : var.resource_group_id
  cloud_monitoring_resource_group_id = var.cloud_monitoring_resource_group_id != null ? var.cloud_monitoring_resource_group_id : var.resource_group_id
  # Some input variable validation (approach based on https://stackoverflow.com/a/66682419)
  log_analysis_validate_condition = var.log_analysis_instance_name != null && var.log_analysis_ingestion_key == null
  log_analysis_validate_msg       = "A value for var.log_analysis_ingestion_key must be passed when providing a value for var.log_analysis_instance_name"
  # tflint-ignore: terraform_unused_declarations
  log_analysis_validate_check         = regex("^${local.log_analysis_validate_msg}$", (!local.log_analysis_validate_condition ? local.log_analysis_validate_msg : ""))
  cloud_monitoring_validate_condition = var.cloud_monitoring_instance_name != null && var.cloud_monitoring_access_key == null
  cloud_monitoring_validate_msg       = "A value for var.cloud_monitoring_access_key must be passed when providing a value for var.cloud_monitoring_instance_name"
  # tflint-ignore: terraform_unused_declarations
  cloud_monitoring_validate_check = regex("^${local.cloud_monitoring_validate_msg}$", (!local.cloud_monitoring_validate_condition ? local.cloud_monitoring_validate_msg : ""))
}

module "observability_agents" {
  count                              = local.run_observability_agents_module == true ? 1 : 0
  source                             = "terraform-ibm-modules/observability-agents/ibm"
  version                            = "1.16.0"
  cluster_id                         = module.ocp_base.cluster_id
  cluster_resource_group_id          = var.resource_group_id
  log_analysis_enabled               = local.provision_log_analysis_agent
  log_analysis_instance_name         = var.log_analysis_instance_name
  log_analysis_ingestion_key         = var.log_analysis_ingestion_key
  log_analysis_resource_group_id     = local.log_analysis_resource_group_id
  log_analysis_agent_version         = var.log_analysis_agent_version
  log_analysis_agent_tags            = var.log_analysis_agent_tags
  cloud_monitoring_enabled           = local.provision_cloud_monitoring_agent
  cloud_monitoring_instance_name     = var.cloud_monitoring_instance_name
  cloud_monitoring_access_key        = var.cloud_monitoring_access_key
  cloud_monitoring_resource_group_id = local.cloud_monitoring_resource_group_id
  cloud_monitoring_agent_version     = var.cloud_monitoring_agent_version
  cloud_monitoring_agent_tags        = var.cloud_monitoring_agent_tags
}
