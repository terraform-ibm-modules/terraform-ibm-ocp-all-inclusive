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
    wait_for_apply   = var.kms_wait_for_apply
  } : null
}

module "ocp_base" {
  source                                = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                               = "3.33.0"
  cluster_name                          = var.cluster_name
  ocp_version                           = var.ocp_version
  resource_group_id                     = var.resource_group_id
  region                                = var.region
  tags                                  = var.cluster_tags
  access_tags                           = var.access_tags
  force_delete_storage                  = var.force_delete_storage
  vpc_id                                = var.vpc_id
  vpc_subnets                           = var.vpc_subnets
  worker_pools                          = var.worker_pools
  cluster_ready_when                    = var.cluster_ready_when
  cos_name                              = var.cos_name
  existing_cos_id                       = var.existing_cos_id
  ocp_entitlement                       = var.ocp_entitlement
  disable_public_endpoint               = var.disable_public_endpoint
  ignore_worker_pool_size_changes       = var.ignore_worker_pool_size_changes
  attach_ibm_managed_security_group     = var.attach_ibm_managed_security_group
  custom_security_group_ids             = var.custom_security_group_ids
  additional_lb_security_group_ids      = var.additional_lb_security_group_ids
  number_of_lbs                         = var.number_of_lbs
  additional_vpe_security_group_ids     = var.additional_vpe_security_group_ids
  kms_config                            = local.kms_config
  addons                                = var.addons
  manage_all_addons                     = var.manage_all_addons
  verify_worker_network_readiness       = var.verify_worker_network_readiness
  cluster_config_endpoint_type          = var.cluster_config_endpoint_type
  enable_registry_storage               = var.enable_registry_storage
  disable_outbound_traffic_protection   = var.disable_outbound_traffic_protection
  operating_system                      = var.operating_system
  import_default_worker_pool_on_create  = var.import_default_worker_pool_on_create
  allow_default_worker_pool_replacement = var.allow_default_worker_pool_replacement
}

##############################################################################
# observability-agents-module
##############################################################################

module "observability_agents" {
  count                                    = var.log_analysis_enabled == true || var.cloud_monitoring_enabled == true ? 1 : 0
  source                                   = "terraform-ibm-modules/observability-agents/ibm"
  version                                  = "1.29.1"
  cluster_id                               = module.ocp_base.cluster_id
  cluster_resource_group_id                = var.resource_group_id
  cluster_config_endpoint_type             = var.cluster_config_endpoint_type
  log_analysis_enabled                     = var.log_analysis_enabled
  log_analysis_ingestion_key               = var.log_analysis_ingestion_key
  log_analysis_agent_tags                  = var.log_analysis_agent_tags
  log_analysis_add_cluster_name            = var.log_analysis_add_cluster_name
  log_analysis_secret_name                 = var.log_analysis_secret_name
  log_analysis_instance_region             = var.log_analysis_instance_region
  log_analysis_endpoint_type               = var.log_analysis_endpoint_type
  log_analysis_agent_custom_line_inclusion = var.log_analysis_agent_custom_line_inclusion
  log_analysis_agent_custom_line_exclusion = var.log_analysis_agent_custom_line_exclusion
  log_analysis_agent_name                  = var.log_analysis_agent_name
  log_analysis_agent_namespace             = var.log_analysis_agent_namespace
  log_analysis_agent_tolerations           = var.log_analysis_agent_tolerations
  cloud_monitoring_enabled                 = var.cloud_monitoring_enabled
  cloud_monitoring_access_key              = var.cloud_monitoring_access_key
  cloud_monitoring_agent_tags              = var.cloud_monitoring_agent_tags
  cloud_monitoring_secret_name             = var.cloud_monitoring_secret_name
  cloud_monitoring_instance_region         = var.cloud_monitoring_instance_region
  cloud_monitoring_endpoint_type           = var.cloud_monitoring_endpoint_type
  cloud_monitoring_metrics_filter          = var.cloud_monitoring_metrics_filter
  cloud_monitoring_add_cluster_name        = var.cloud_monitoring_add_cluster_name
  cloud_monitoring_agent_name              = var.cloud_monitoring_agent_name
  cloud_monitoring_agent_namespace         = var.cloud_monitoring_agent_namespace
  cloud_monitoring_agent_tolerations       = var.cloud_monitoring_agent_tolerations
}
