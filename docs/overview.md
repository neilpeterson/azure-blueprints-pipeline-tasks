# Quickstart: Azure Blueprints tasks for Azure Pipelines

Before using the Azure Blueprint tasks for Azure Pipelines, you need a Blueprint definition and all artifacts ready to go. For more information on creating Azure Blueprints, see the [Azure Blueprints documentation](https://docs.microsoft.com/en-us/azure/governance/blueprints/?WT.mc_id=blueprintsextension-github-nepeters).

## Create Blueprint Task

Create a task with the following schema to create a blueprint.

```
steps:
- task: nepeters.azure-blueprints.CreateBlueprint.CreateBlueprint@1
  displayName: 'Create Azure Blueprint'
  inputs:
    azureSubscription: 'nepeters-devops-mgmt'
    BlueprintName: 'blueprints-demo'
    BlueprintPath: create
    PublishBlueprint: true
```

All configuration parameters:

| Name | Description | Type | Required | Default Value |
|:---|:---|---|--|--|
| azureSubscription | Azure service connection name. | string | true | |
| blueprintName | The blueprint name. | string | true | |
| blueprintPath | The path to a directory that contains the blueprint.json file.| string | true | |
| AlternateLocation | Give a value of `true` if the blueprint should be created at an alternate subscription (requires Management Group scope). | bool | false | |
| AlternateSubscription | Alternate subscription id (requires Management Group scope). | string | false | |
| publishBlueprint | A value of true indicates the blueprint should be published. | boolean | false | true |
| version | A value of Increment will increment the version number if the version is an integer'. | string | false | increment |

## Assign Blueprint

Create a task with the following schema to assign a blueprint.

```
steps:
- task: nepeters.azure-blueprints.AssignBlueprint.AssignBlueprint@1
  displayName: 'Assign Azure Blueprint'
  inputs:
    azureSubscription: 'nepeters-internal'
    AssignmentName: 'prod-test-one'
    BlueprintName: 'prod-test-one'
    ParametersFile: 'assign/assign-blueprint.json'
    AlternateSubscription: true
    AltSubscriptionID: '00000000-0000-0000-0000-000000000000'
    Wait: true
    StopOnFailure: true
```

All configuration parameters:

| Name | Description | Type | Required | Default Value |
|:---|:---|---|--|--|
| azureSubscription | Azure service connection name. | string | true | |
| BlueprintName | The blueprint name. | string | true | |
| BlueprintVersion | The version of the blueprint to assign | string | false | latest |
| ParametersFile | The path to a JSON file containing the assignment details and parameter values. | string | true | |
| SubscriptionID | The Azure subscription at which the blueprint is stored and / or where the blueprint will be assigned.  | string | false ||
| Wait | Wait for assignment to complete before moving to the next task.  | boolean | false | false |
| Timeout | Time in seconds before wait timeout'  | string | false | 240 |
| StopOnFailure | Will cause the pipeline to fail on assignment failure | boolean | false | false |