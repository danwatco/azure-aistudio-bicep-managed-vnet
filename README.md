# Azure AI Studio Managed Virtual Network in Bicep

This set of templates demonstrates how to set up Azure AI Studio with a managed VNet configuration with internet outbound access enabled. This uses private connections for all the workspace resources, including the connection to Azure OpenAI.
 
Optionally, you can deploy this solution with a VPN gateway and Private DNS resolver to allow access from your local machine.

<!-- This also creates a virtual machine and a Bastion deployment for access so that you can test the deployment by using it as a jumpbox to connect to AI Studio.  -->

This project contains some use of [Azure Verified Modules](https://aka.ms/avm) and was further developed from the Azure sample at [https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.machinelearningservices/aistudio-basics](https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.machinelearningservices/aistudio-basics)

## Resources

| Provider and type | Description |
| - | - |
| `Microsoft.Resources/resourceGroups` | The resource group all resources get deployed into |
| `Microsoft.KeyVault/vaults` | An Azure Key Vault instance associated to the Azure Machine Learning workspace |
| `Microsoft.Storage/storageAccounts` | An Azure Storage instance associated to the Azure Machine Learning workspace |
| `Microsoft.ContainerRegistry/registries` | An Azure Container Registry instance associated to the Azure Machine Learning workspace |
| `Microsoft.MachineLearningServices/workspaces` | An Azure AI hub (Azure Machine Learning RP workspace of kind 'hub') |
| `Microsoft.CognitiveServices/accounts` | An Azure AI Services as the model-as-a-service endpoint provider (allowed kinds: 'AIServices' and 'OpenAI') |
| `Microsoft.Network/virtualNetworks` | A virtual network to host the VM and private endpoints |
| `Microsoft.Network/privateEndpoints` | Private endpoints for private connections to the services including storage. |
| `Microsoft.Network/privateDnsZones` | Private DNS zones for private endpoints |
| `Microsoft.Network/virtualNetworkGateways` | Virtual network gateway for Point to site VPN |
| `Microsoft.Network/dnsResolvers` | Private DNS resolvers to allow local machine to access private endpoints |


## Deployment Steps


1. Update `main.parameters.json` 

2. Deploy infra using Azure CLI

```bash
az group deployment create -g <RESOURCE_GROUP> -f main.bicep -p main.parameters.json
```

3. Change the DNS servers on the VNet to the deployed inbound endpoint from the private DNS resolver

4. Use the steps detailed [here on Microsoft Learn](https://learn.microsoft.com/en-us/azure/vpn-gateway/point-to-site-entra-gateway#point-to-site-workflow) to configure Point-to-Site with Entra ID authentication

1. Edit the downloaded `azurevpnconfig.xml` file and insert the following in the `<clientconfig>` block below the DNS servers:

```xml
<dnssuffixes>
    <dnssuffix>.core.windows.net</dnssuffix>
    <dnssuffix>.api.azureml.ms</dnssuffix>
    <dnssuffix>.notebooks.azure.net</dnssuffix>
    <dnssuffix>.openai.azure.com</dnssuffix>
    <dnssuffix>.vaultcore.azure.net</dnssuffix>
    <dnssuffix>.cognitiveservices.azure.com</dnssuffix>
</dnssuffixes>
```

This ensures that your local machine forwards DNS requests for those domains to the private resolver

6. Connect to VPN and access AI Studio


## Post Deployment

After deployment, in order to provision the managed VNet without creating a compute instance you can use the following Azure CLI command:

```azurecli
az ml workspace provision-network -g my_resource_group -n my_workspace_name
```

See more here: [https://learn.microsoft.com/en-us/azure/machine-learning/how-to-managed-network?view=azureml-api-2&tabs=azure-cli#manually-provision-a-managed-vnet](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-managed-network?view=azureml-api-2&tabs=azure-cli#manually-provision-a-managed-vnet)

## Learn more

If you are new to Azure AI studio, see:

- [Azure AI studio](https://aka.ms/aistudio/docs)
