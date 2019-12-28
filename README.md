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