# Quickstart: Azure Blueprints tasks for Azure Pipelines

## Pre-create Azure Credentials

If your Blueprints will be created and managed at an Azure Management Group a pre-created service principal is required. This is due to a current limitation with the built-in service connections. If your Blueprints will be created and managed at an Azure Subscription, skip to the next step.

Create a service principal using the [az ad sp create-for-rbac](https://docs.microsoft.com/en-us/cli/azure/ad/sp?WT.mc_id=none-github-nepeters&view=azure-cli-latest#az-ad-sp-create-for-rbac) command.

```
$ az sp create-for-rbac

{
  "appId": "b9badc25-0000-0000-0000-0e015cff62dc",
  "displayName": "azure-cli-2019-04-10-12-48-25",
  "name": "http://azure-cli-2019-04-10-12-48-25",
  "password": "8741ec3c-0000-0000-0000-b66e70aede43",
  "tenant": "72f988bf-0000-0000-0000-2d7cd011db47"
}
```

Grant the service principal access to the management group using the [az role assignment create](https://docs.microsoft.com/en-us/cli/azure/role/assignment?WT.mc_id=none-github-nepeters&view=azure-cli-latest#az-role-assignment-create) command. The assignee is the appId of the service principal and the scope is the ID of the management group.

Using the following example, replace `management-group-name` with the name of your management group.

```
az role assignment create --role owner --assignee b9badc25-0000-0000-0000-0e015cff62dc --scope https://management.azure.com/providers/Microsoft.Management/managementGroups/management-group-name
```

## Create Azure DevOps Serive Connection

Create an Azure DevOps project and then a new service connection with the type `Azure Resource Manager`. If your Blueprints will be created and managed at a Management Group, select `ManagementGroup` for the scope level, select `use the full version of the service connection dialog`, and fill out the form with the credentials created in the last step.

![alt text](./images/mg-service-connection.png)

If your Blueprints will be created and managed at a subscription, select the subscription.

![alt text](./images/sub-service-connection.png)

## Create Blueprint Task

Create a task with the following schema to create a blueprint.

```
- task: CreateBlueprint@1
  inputs:
    ConnectedServiceName: 'nepeters-internal-managemet-group'
    BlueprintName: 'blueprints-demo'
    BlueprintPath: './create/blueprint-body.json'
    ArtifactsPath: './create/artifacts'
    PublishBlueprint: true
```

## Assign Blueprint

Create a task with the following schema to assign a blueprint.

```
- task: AssignBlueprint@1
  inputs:
    ConnectedServiceName: 'nepeters-internal-managemet-group'
    BlueprintName: 'blueprints-demo'
    ParametersFile: './assign/assign-blueprint.json'
    SubscriptionID: '3762d87c-0000-0000-0000-29e5e859edaf'
```