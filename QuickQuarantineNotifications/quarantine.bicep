param functionName string


resource function 'Microsoft.Web/sites/functions@2022-09-01' = {
  name: functionName
  properties: {
    files: 
  }
}
