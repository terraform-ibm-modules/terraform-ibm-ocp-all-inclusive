##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# VPC
##############################################################################

module "vpc" {
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "7.18.1"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  tags              = var.resource_tags
  name              = "${var.prefix}-vpc"
}

##############################################################################
# Observability Instances (Log Analysis + Cloud Monitoring)
##############################################################################

module "observability_instances" {
  source  = "terraform-ibm-modules/observability-instances/ibm"
  version = "2.12.2"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  region                         = var.region
  resource_group_id              = module.resource_group.resource_group_id
  activity_tracker_provision     = false
  log_analysis_instance_name     = "${var.prefix}-logdna"
  cloud_monitoring_instance_name = "${var.prefix}-sysdig"
  log_analysis_plan              = "7-day"
  cloud_monitoring_plan          = "graduated-tier"
  enable_platform_logs           = false
  enable_platform_metrics        = false
  log_analysis_tags              = var.resource_tags
  cloud_monitoring_tags          = var.resource_tags
}

##############################################################################
# Key Protect All Inclusive
##############################################################################

locals {
  key_ring_name = "ocp-key-ring"
  key_name      = "ocp-key"
}

module "key_protect_all_inclusive" {
  source                    = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                   = "4.13.1"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  keys = [
    {
      key_ring_name = (local.key_ring_name)
      keys = [
        {
          key_name = local.key_name
        }
      ]
    }
  ]
}

##############################################################################
# OCP All Inclusive Module
##############################################################################

locals {
  addons = {
    "cluster-autoscaler" = "1.2.0"
  }

  cluster_vpc_subnets = {
    zone-1 = [
      for zone in module.vpc.subnet_zone_list :
      {
        id         = zone.id
        zone       = zone.zone
        cidr_block = zone.cidr
      }
    ]
  }
}

module "ocp_all_inclusive" {
  source                           = "../.."
  ibmcloud_api_key                 = var.ibmcloud_api_key
  resource_group_id                = module.resource_group.resource_group_id
  region                           = var.region
  cluster_name                     = "${var.prefix}-cluster"
  cos_name                         = "${var.prefix}-cos"
  vpc_id                           = module.vpc.vpc_id
  vpc_subnets                      = local.cluster_vpc_subnets
  worker_pools                     = var.worker_pools
  ocp_version                      = var.ocp_version
  cluster_tags                     = var.resource_tags
  access_tags                      = var.access_tags
  existing_kms_instance_guid       = module.key_protect_all_inclusive.kms_guid
  existing_kms_root_key_id         = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].key_id
  log_analysis_instance_region     = module.observability_instances.region
  log_analysis_ingestion_key       = module.observability_instances.log_analysis_ingestion_key
  cloud_monitoring_access_key      = module.observability_instances.cloud_monitoring_access_key
  cloud_monitoring_instance_region = module.observability_instances.region
  addons                           = local.addons
  disable_public_endpoint          = var.disable_public_endpoint
  log_analysis_agent_tags          = var.resource_tags
  cloud_monitoring_agent_tags      = var.resource_tags
}
