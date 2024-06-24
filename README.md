
# Azure AI Studio Managed Virtual Network Setup with Bicep

This set of templates demonstrates how to set up Azure AI Studio with a managed vnet configuration with internet outbound access enabled. This uses private connections for all the workspace resources, including the connection to Azure OpenAI.
 
This also creates a virtual machine and a Bastion deployment for access so that you can test the deployment by using it as a jumpbox to connect to the environment. 

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
| `Microsoft.Compute/virtualMachines` | Virtual machine to use for jumpbox. |
| `Microsoft.Network/networkInterfaces` | A network interface for the VM |
| `Microsoft.Compute/disks` | A disk for the VM |
| `Microsoft.Network/bastionHosts` | A bastion host for secure access to the virtual machine. |


## Post Deployment

After deployment, in order to provision the managed VNet without creating a compute instance you can use the following Azure CLI command.

```azurecli
az ml workspace provision-network -g my_resource_group -n my_workspace_name
```

See more here: [https://learn.microsoft.com/en-us/azure/machine-learning/how-to-managed-network?view=azureml-api-2&tabs=azure-cli#manually-provision-a-managed-vnet](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-managed-network?view=azureml-api-2&tabs=azure-cli#manually-provision-a-managed-vnet)




## Learn more

If you are new to Azure AI studio, see:

- [Azure AI studio](https://aka.ms/aistudio/docs)
