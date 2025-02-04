package test

import (
	"log"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const CompleteExampleTerraformDir = "examples/end-to-end-example"
const basicExampleDir = "examples/basic"
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

func setupOptionsBasic(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  dir,
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
	})
	return options
}

func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := setupOptionsBasic(t, "basic-ocp", basicExampleDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
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
		WaitJobCompleteMinutes: 120,
		IgnoreUpdates: testhelper.Exemptions{
			List: []string{
				// skip this due to the dummy value being set to always force update the logs-agent helm release
				"module.ocp_all_inclusive.module.observability_agents[0].module.logs_agent[0].helm_release.logs_agent",
			},
		},
	})

	// Setting up variables for the Schematics test
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ocp_version", Value: "4.16", DataType: "string"},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "visibility", Value: "private", DataType: "string"},
		{Name: "import_default_worker_pool_on_create", Value: false, DataType: "bool"},
	}
	// Run the Schematics test
	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunUpgradeCompleteExampleInSchematics(t *testing.T) {
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
		WaitJobCompleteMinutes: 120,
		IgnoreUpdates: testhelper.Exemptions{
			List: []string{
				// skip this due to the dummy value being set to always force update the logs-agent helm release
				"module.ocp_all_inclusive.module.observability_agents[0].module.logs_agent[0].helm_release.logs_agent",
			},
		},
	})

	// Setting up variables for the Schematics test
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ocp_version", Value: "4.16", DataType: "string"},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "visibility", Value: "private", DataType: "string"},
		{Name: "import_default_worker_pool_on_create", Value: false, DataType: "bool"},
	}
	// Run the Schematics test
	err := options.RunSchematicUpgradeTest()
	assert.Nil(t, err, "This should not have errored")
}
