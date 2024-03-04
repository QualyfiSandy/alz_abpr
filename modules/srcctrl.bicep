param paramsrcctrlname string
param pAppServiceName string

resource resAppService 'Microsoft.Web/sites@2022-09-01' existing = {
  name: pAppServiceName
}

resource resProdSrcControls 'Microsoft.Web/sites/sourcecontrols@2022-09-01' = {
  name: paramsrcctrlname
  kind: 'app'
  parent: resAppService
  properties: {
    repoUrl: 'https://github.com/Azure-Samples/dotnetcore-docs-hello-world'
    branch: 'master'
    deploymentRollbackEnabled: true
    isManualIntegration: true
    isGitHubAction: false
    isMercurial: false
      }
    }
