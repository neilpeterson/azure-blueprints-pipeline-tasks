# Azure Pipeline tasks for Azure Blueprints

**Current Status**: Proof of concept / iterating on UX. The intention for this project is to refactor into Typescript once capability and functionality feels right.

For configuration and capibility instructions see the [quickstart doc](./docs/overview.md).

A sample Blueprint and task examples are available [here](https://github.com/neilpeterson/blueprint-example).

## Build and deploy tasks

Install the Node CLI for Azure DevOps, this requires Node.js 4.0.x.

```
npm install -g tfx-cli
```

Use [tfx extension create](https://docs.microsoft.com/en-us/azure/devops/extend/get-started/node?WT.mc_id=none-github-nepeters&view=azure-devops) command to build the extension .vsix file.

```
tfx extension create --manifest-globs vss-extension.json
```

Import the .vsix file into your own Visual Studio Marketplace - https://marketplace.visualstudio.com/manag .

## Log

**3-29-2019 v1.0.0** - Initial POC

**4-14-2019 v1.1.0** - Removed UI for blueprint location and management group name. This is now inferred from the service connection. Updated docs with steps to create a service connection.

**5-08-2019 v1.1.3** - Added logic to remove / reestablish artifacts from code. Also updated API version across all methods.

**5-08-2019 v1.1.4** - Refactored REST URI creation to use string builder and a helper function.

**5-08-2019 v1.1.5** - Renamed extension.

**5-10-2019 v1.1.6** - Added logic to create Blueprint at specified subscription.

**5-13-2019 v1.1.7** - Added logic to create and assign from an alternate location (non-service connection scoped subscription.) Update Management Group logic to use the ID instead of the name.

**7-07-2019 v1.2.1** - Extension converted to use Az.Blueprints PowerShell module which fixes [Issue 24](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/24) and [Issue 23](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/23) . Adds version-specific assignment to fix [Issue 25](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/25). Adds a wait on assignment to fix [Issue 14](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/14).

**7-11-2019 v1.2.7** - Metadata and docs for marketplace publishing.

**9-11-2019 v1.4.1** - Added Set-AzBlueprintAssignment for idempotency which fixes [Issue 30](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/30).

**9-12-2019 v1.5.0** - Added support for soverign cloud environments. [Issue 36](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/36)

**9-23-2019 v1.5.1** - [Issue 38](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/38), [Issue 35](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/35), [Issue 30](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/30)

**10-25-2019 v1.5.4** - [Issue 42](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/42)

**10-25-2019 v1.5.5** - [Issue 33](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/33)

**10-25-2019 v1.5.6** - [Issue 48](https://github.com/neilpeterson/azure-blueprints-pipeline-tasks/issues/48)