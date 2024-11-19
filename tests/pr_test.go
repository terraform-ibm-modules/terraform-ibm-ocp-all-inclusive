package test

import (
	"log"
	"os"
	"testing"

	//"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const CompleteExampleTerraformDir = "examples/end-to-end-example"
const resourceGroup = "geretain-test-ocp-all-inclusive"

const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}

func TestMain(m *testing.M) {
	// Read the YAML file contents
	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, terraformVars map[string]interface{}) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  CompleteExampleTerraformDir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.ocp_all_inclusive.module.observability_agents[0].helm_release.logdna_agent[0]",
				"module.ocp_all_inclusive.module.observability_agents[0].helm_release.sysdig_agent[0]",
				"module.ocp_all_inclusive.module.observability_agents[0].module.logs_agent[0].helm_release.logs_agent",
				"module.ocp_all_inclusive.module.observability_agents[0].helm_release.cloud_monitoring_agent[0]",
			},
		},
		ImplicitDestroy: []string{ // Ignore full destroy to speed up tests
			"module.ocp_all_inclusive.module.observability_agents",
			"module.ocp_all_inclusive.module.ocp_base.null_resource.confirm_network_healthy",
			// workaround for the issue https://github.ibm.com/GoldenEye/issues/issues/10743
			// when the issue is fixed on IKS, so the destruction of default workers pool is correctly managed on provider/clusters service the next two entries should be removed
			"'module.ocp_all_inclusive.module.ocp_base.ibm_container_vpc_worker_pool.autoscaling_pool[\"default\"]'",
			"'module.ocp_all_inclusive.module.ocp_base.ibm_container_vpc_worker_pool.pool[\"default\"]'",
		},
		ImplicitRequired: false,
		TerraformVars:    terraformVars,
	})

	return options
}

func TestCompleteExampleInSchematics(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "ocp-all-inc",
		TarIncludePatterns: []string{
			"*.tf",
			"examples/end-to-end-example/*.tf",
			"examples/end-to-end-example/kubeconfig/README.md",
		},
		ResourceGroup:          resourceGroup,
		TemplateFolder:         CompleteExampleTerraformDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	// Setting up variables for the Schematics test
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ocp_version", Value: "4.16", DataType: "string"},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "visibility", Value: "private", DataType: "string"},
	}

	// Run the Schematics test
	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunUpgradeCompleteExample(t *testing.T) {
	t.Parallel()

	terraformVars := map[string]interface{}{
		// This test should always test the OCP version not tested in the "TestRunCompleteExample" test.
		"ocp_version": "4.15",
	}
	options := setupOptions(t, "ocp-all-upg", terraformVars)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
