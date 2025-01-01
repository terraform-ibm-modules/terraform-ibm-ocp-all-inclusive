output "cluster_id" {
  description = "ID of cluster created"
  value       = module.ocp_all_inclusive.cluster_id
}

output "cluster_name" {
  description = "Name of the created cluster"
  value       = module.ocp_all_inclusive.cluster_name
}

output "cluster_crn" {
  description = "CRN for the created cluster"
  value       = module.ocp_all_inclusive.cluster_crn
}

output "workerpools" {
  description = "Worker pools created"
  value       = module.ocp_all_inclusive.workerpools
}

output "ocp_version" {
  description = "Openshift Version of the cluster"
  value       = module.ocp_all_inclusive.ocp_version
}

output "cos_crn" {
  description = "The IBM Cloud Object Storage instance CRN used to back up the internal registry in the OCP cluster."
  value       = module.ocp_all_inclusive.cos_crn
}

output "vpc_id" {
  description = "ID of the clusters VPC"
  value       = module.ocp_all_inclusive.vpc_id
}

output "region" {
  description = "Region cluster is deployed in"
  value       = var.region
}

output "resource_group_id" {
  description = "Resource group ID the cluster is deployed in"
  value       = module.ocp_all_inclusive.resource_group_id
}

output "ingress_hostname" {
  description = "The hostname that was assigned to the OCP clusters Ingress subdomain."
  value       = module.ocp_all_inclusive.ingress_hostname
}

output "private_service_endpoint_url" {
  description = "Private service endpoint URL"
  value       = module.ocp_all_inclusive.private_service_endpoint_url
}

output "public_service_endpoint_url" {
  description = "Public service endpoint URL"
  value       = module.ocp_all_inclusive.public_service_endpoint_url
}

# output "sdnlb_ips" {
#   description = "List of external IP addresses for the sDNLB service"
#   value       = module.ocp_all_inclusive.sdnlb_ips
# }
