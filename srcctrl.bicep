param paramsrcctrlname string

resource resProdSrcControls 'Microsoft.Web/sites/sourcecontrols@2022-09-01' = {
  name: paramsrcctrlname
  properties: {
    repoUrl: 'https://github.com/Azure-Samples/dotnetcore-docs-hello-world'
    branch: 'master'
    isManualIntegration: true
      }
    }
