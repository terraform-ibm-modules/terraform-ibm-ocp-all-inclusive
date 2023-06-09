package test

import (
	"log"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const basicExampleTerraformDir = "examples/end-to-end-example"
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
		TerraformDir:  basicExampleTerraformDir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.ocp_all_inclusive.module.observability_agents[0].helm_release.logdna_agent[0]",
				"module.ocp_all_inclusive.module.observability_agents[0].helm_release.sysdig_agent[0]",
			},
		},
		ImplicitDestroy: []string{ // Ignore full destroy to speed up tests
			"module.ocp_all_inclusive.module.observability_agents",
			"module.ocp_all_inclusive.module.ocp_base.null_resource.confirm_network_healthy",
		},
		ImplicitRequired: false,
		TerraformVars:    terraformVars,
	})

	return options
}

func testRunComplete(t *testing.T, version string) {
	t.Parallel()

	terraformVars := map[string]interface{}{
		"ocp_version": version,
		"access_tags": permanentResources["accessTags"],
	}
	options := setupOptions(t, "ocp-all-inc", terraformVars)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunCompleteExample(t *testing.T) {
	t.Parallel()

	// This test should always test the latest supported OCP version. Previous versions will be tested in other_test.go
	versions := []string{"4.11", "4.12"}
	for _, version := range versions {
		t.Run(version, func(t *testing.T) { testRunComplete(t, version) })
	}
}

func TestRunUpgradeCompleteExample(t *testing.T) {
	t.Parallel()

	terraformVars := map[string]interface{}{
		// This test should always test the latest supported OCP version. Previous versions will be tested in other_test.go
		"ocp_version": "4.11",
	}
	options := setupOptions(t, "ocp-all-upg", terraformVars)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
