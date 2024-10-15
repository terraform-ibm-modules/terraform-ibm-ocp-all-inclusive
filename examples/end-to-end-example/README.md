# Complete Example

An end-to-end example that will:
- Create a new resource group (if existing one is not passed in).
- Provision a VPC in the given resource group and region.
- Define ACLs to allow inbound and outboud traffic:
  - from/to Ingress Operator to correctly report cluster ingress status
  - to the cluster's oAuth server port to enable the Openshift cluster console
- Provision Cloud Logs and Cloud Monitoring instances in the given resource group and region.
- Provision a Key Protect instance in the given resource group and region and create a new key ring and key in the instance
- Call the ocp-all-inclusive-module to do the following:
  - provision an OCP VPC cluster in the given resource group and region, passing the details of the Key Protect instance and key for cluster encryption
  - deploy Logs Agent and Cloud Monitoring agents to the cluster
  - deploy service mesh on the cluster
  - install autoscaler addon and configure certain nodepools to have autoscaling enabled.
