# Azure Pipeline tasks for Azure Blueprints

**Current Status**: Proof of concept / iterating on UX. The intention for this project is to refactor into Typescript once capability and functionality feels right.

For configuration and capibility instructions see the [quickstart doc](./docs/quickstart.md).

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

**5-17-2019 v1.1.3** - Added logic to remove / reestablish artifacts from code. Also updated API version across all methods.

**5-17-2019 v1.1.4** - Refactored REST URI creation to use string builder and a helper function.