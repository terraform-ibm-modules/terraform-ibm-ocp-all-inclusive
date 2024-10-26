##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix.
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# VPC
##############################################################################

locals {
  # extending ACL rules to allow outbound and inbound traffic for the OpenShift ingress healthcheck operator and Openshift console access (port 443) and to allow OpenShift console to reach oAuth server (port in nodePort interval)

  # ACL rules to allow inbound and oubound traffic for OpenShift ingress healthcheck operator traffic and inbound traffic to access OpenShift console
  acl_rules_ingress_healthcheck_operator = [
    {
      name      = "https-inbound-tcp-to-443"
      action    = "allow"
      direction = "inbound"
      tcp = {
        port_min = 443
        port_max = 443
      }
      destination = "0.0.0.0/0"
      source      = "0.0.0.0/0"
    },
    {
      name      = "https-inbound-tcp-from-443"
      action    = "allow"
      direction = "inbound"
      tcp = {
        source_port_min = 443
        source_port_max = 443
      }
      destination = "0.0.0.0/0"
      source      = "0.0.0.0/0"
    },
    {
      name      = "https-outbound-tcp-to-443"
      action    = "allow"
      direction = "outbound"
      tcp = {
        port_min = 443
        port_max = 443
      }
      destination = "0.0.0.0/0"
      source      = "0.0.0.0/0"
    },
    {
      name      = "https-outbound-tcp-from-443"
      action    = "allow"
      direction = "outbound"
      tcp = {
        source_port_min = 443
        source_port_max = 443
      }
      destination = "0.0.0.0/0"
      source      = "0.0.0.0/0"
    }
  ]

  # ACL rules to allow traffic to oAuth server to enable OpenShift console
  acl_rules_openshift_console_oauth = [
    {
      name      = "oauth-allow-inbound-traffic"
      action    = "allow"
      direction = "inbound"
      tcp = {
        source_port_min = 30000
        source_port_max = 32767
      }
      destination = "0.0.0.0/0"
      source      = "0.0.0.0/0"
    },
    {
      name      = "oauth-allow-outbound-traffic"
      action    = "allow"
      direction = "outbound"
      tcp = {
        port_min = 30000
        port_max = 32767
      }
      destination = "0.0.0.0/0"
      source      = "0.0.0.0/0"
    }
  ]


  acl_rules = [
    {
      name                         = "${var.prefix}-acls"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      rules                        = setunion(local.acl_rules_ingress_healthcheck_operator, local.acl_rules_openshift_console_oauth)
    }
  ]
}

module "vpc" {
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "7.19.0"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  tags              = var.resource_tags
  network_acls      = local.acl_rules
  name              = "${var.prefix}-vpc"
  subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "${var.prefix}-acls"
        no_addr_prefix = false
      }
    ],
    zone-2 = [
      {
        name           = "subnet-b"
        cidr           = "10.20.10.0/24"
        public_gateway = true
        acl_name       = "${var.prefix}-acls"
        no_addr_prefix = false
      }
    ],
    zone-3 = [
      {
        name           = "subnet-c"
        cidr           = "10.30.10.0/24"
        public_gateway = true
        acl_name       = "${var.prefix}-acls"
        no_addr_prefix = false
      }
    ]
  }
  use_public_gateways = {
    zone-1 = true
    zone-2 = true
    zone-3 = true
  }
}

##############################################################################
# Observability Instances (Cloud Logs + Cloud Monitoring)
##############################################################################

module "observability_instances" {
  source                         = "terraform-ibm-modules/observability-instances/ibm"
  version                        = "3.1.1"
  region                         = var.region
  resource_group_id              = module.resource_group.resource_group_id
  cloud_logs_instance_name       = "${var.prefix}-icl"
  cloud_monitoring_instance_name = "${var.prefix}-sysdig"
  cloud_monitoring_plan          = "graduated-tier"
  enable_platform_logs           = false
  enable_platform_metrics        = false
  cloud_logs_tags                = var.resource_tags
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
  version                   = "4.16.5"
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
    "cluster-autoscaler" = "1.2.1"
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
  cloud_logs_ingress_endpoint      = module.observability_instances.cloud_logs_ingress_private_endpoint
  cloud_logs_ingress_port          = 3443
  cloud_monitoring_access_key      = module.observability_instances.cloud_monitoring_access_key
  cloud_monitoring_instance_region = module.observability_instances.region
  addons                           = local.addons
  disable_public_endpoint          = var.disable_public_endpoint
  cloud_monitoring_agent_tags      = var.resource_tags
}
