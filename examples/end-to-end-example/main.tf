##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# VPC
##############################################################################

module "vpc" {
  source            = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=v7.2.0"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  tags              = var.resource_tags
  name              = "${var.prefix}-vpc"
}

##############################################################################
# Observability Instances (LogDNA + Sysdig)
##############################################################################

module "observability_instances" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances?ref=v2.7.0"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  region                     = var.region
  resource_group_id          = module.resource_group.resource_group_id
  activity_tracker_provision = false
  logdna_instance_name       = "${var.prefix}-logdna"
  sysdig_instance_name       = "${var.prefix}-sysdig"
  logdna_plan                = "7-day"
  sysdig_plan                = "graduated-tier"
  enable_platform_logs       = false
  enable_platform_metrics    = false
  logdna_tags                = var.resource_tags
  sysdig_tags                = var.resource_tags
}

##############################################################################
# Key Protect All Inclusive
##############################################################################

locals {
  key_ring_name = "ocp-key-ring"
  key_name      = "ocp-key"
}

module "key_protect_all_inclusive" {
  source                    = "git::https://github.com/terraform-ibm-modules/terraform-ibm-key-protect-all-inclusive.git?ref=v4.2.0"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  key_protect_instance_name = "${var.prefix}-kp"
  resource_tags             = var.resource_tags
  key_map = {
    (local.key_ring_name) = [local.key_name]
  }
}

##############################################################################
# OCP All Inclusive Module
##############################################################################

locals {
  addons = {
    "cluster-autoscaler" = "1.0.8"
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
  source                             = "../.."
  ibmcloud_api_key                   = var.ibmcloud_api_key
  resource_group_id                  = module.resource_group.resource_group_id
  region                             = var.region
  cluster_name                       = "${var.prefix}-cluster"
  cos_name                           = "${var.prefix}-cos"
  vpc_id                             = module.vpc.vpc_id
  vpc_subnets                        = local.cluster_vpc_subnets
  worker_pools                       = var.worker_pools
  ocp_version                        = var.ocp_version
  cluster_tags                       = var.resource_tags
  existing_key_protect_instance_guid = module.key_protect_all_inclusive.key_protect_guid
  existing_key_protect_root_key_id   = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].key_id
  logdna_instance_name               = module.observability_instances.logdna_name
  logdna_ingestion_key               = module.observability_instances.logdna_ingestion_key
  sysdig_instance_name               = module.observability_instances.sysdig_name
  sysdig_access_key                  = module.observability_instances.sysdig_access_key
  addons                             = local.addons
}
