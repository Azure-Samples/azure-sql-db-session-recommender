---
page_type: sample
languages:
- csharp
- sql
- tsql
products:
- azure-functions
- azure-sql-database
- static-web-apps
- sql-server
- azure-sql-managed-instance
- azure-sqlserver-vm
- dotnet
- azure-openai
name: Session Recommender using Azure SQL DB, Open AI and Vector Search
description: Build a session recommender using Jamstack and Event-Driven architecture, using Azure SQL DB to store and search vectors embeddings generated using OpenAI
---

# Session Recommender Sample

![Architecture Diagram](./_docs/session-recommender-architecture.png)

A session recommender built using

- [Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/overview)
- [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
- [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview?pivots=programming-language-csharp)
- [Azure SQL Database](https://www.sqlservercentral.com/articles/the-sql-developer-experience-beyond-rdbms)
- [Data API builder](https://aka.ms/dab)

For more details on the solution check also the following articles:

- [How I built a session recommender in 1 hour using Open AI](https://dev.to/azure/how-i-built-a-session-recommender-in-1-hour-using-open-ai-5419)
- [Vector Similarity Search with Azure SQL database and OpenAI](https://devblogs.microsoft.com/azure-sql/vector-similarity-search-with-azure-sql-database-and-openai/)

## Getting Started

Make sure you have [AZ CLI installed](https://learn.microsoft.com/en-us/cli/azure/). It is also recommeneded to use VS Code with the Azure Functions extension installed.

## Create the resource group

Create a new resource group using the following command:

```bash
az group create -g <your-resource-group-name> -l <location>
```

## Create the Azure OpenAI service

Create a new [Azure OpenAI service](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=cli) in the resource group created in the previous step using the following command:

```bash
az cognitiveservices account create --name <your-openai-name> --resource-group <your-resource-group-name> --kind OpenAI --sku s0
```

Create an [embedding model](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#embeddings-models) using the [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=web-portal) and name it `embeddings`. Make sure to use the `text-embedding-ada-002` mode. Once the resource is created, create a `azuredeploy.parameters.json` file using the provided sample file and add the API key and the API url. If you want to also test everything locally, also create a `.env` file from the provided sample and add the API key and url also there. 

## Deploy the solution

Fork this repository and then clone the forked respository locally.

### Deploy the database

Create an new [Azure SQL database](https://learn.microsoft.com/en-us/azure/azure-sql/database/single-database-create-quickstart?view=azuresql&tabs=azure-portal), then run the `./database/setup-database.sql` script to set up the database.

It is recommened to use Azure Data Studio to run the script. Make sure that the `SQLCMD` mode is enabled. To enable `SQLCMD` mode, click on the `SQLCMD` button in the toolbar.

Before running the script set the values for the SQLCMD variable on top of the script:

```
:setvar OpenAIUrl https://<your-openai-service>.openai.azure.com
:setvar OpenAIKey <your-key>
```

using the value from the OpenAI service created in the previous step.

Then run the script to create the database objects.

### Deploy Static Web App and Azure Function

Replace the placeholders values in the `azuredeploy.parameters.json` file with the correct values for your environment. Follow the documentation here: [Managing your personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) to get the GitHub token needed to deploy the Static Web App. Make sure the token created is a "classic" token that has access to the following scopes: **repo, workflow, write:packages**

Then run the following command to create the resources in Azure. 

```bash
az deployment group create --resource-group <your-resource-group-name> --template-file main.bicep --parameters azuredeploy.parameters.json
```

The deployment process will create 
- Static Web App
- Function
- Storage Account
- Application Insight

The deployment process will also automatically deploy the code of the referenced repository intpo the created Static Web App. 

### Configure the Static Web App 

Now that the Static Web App has been deployed, it needs to be linked the Static Web App to the created database using the [Database Connections](https://learn.microsoft.com/en-us/azure/static-web-apps/database-overview) feature. Follow the instructions in the [Configure database connectivity](https://learn.microsoft.com/en-us/azure/static-web-apps/database-configuration#configure-database-connectivity) to configure the database connection.

#### (Optional) Use a custom authentication provider with Static Web Apps

The folder `api` contains a sample function to customize the authentication process as described in the [Custom authentication in Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/authentication-custom?tabs=aad%2Cinvitations#configure-a-custom-identity-provider) article. The function will add any user with a `@microsoft.com` to the `microsoft` role. Data API builder can be configured to allow acceess to a certain API only to users with a certain role, for example:

```json
"permissions": [
    {
        "role": "microsoft",
        "actions": [
        {
            "action": "execute"
        }
        ]
    }
]
```

This step is optional and is provided mainly as an example on how to use custom authentication with SWA and DAB. It is not used in the solution.

### Deploy the Azure Function

The function to use OpenAI to convert session title and abstract into embeddings is in the `func` folder. It uses the [Azure SQL trigger for Functions](https://learn.microsoft.com/azure/azure-functions/functions-bindings-azure-sql-trigger?tabs=isolated-process%2Cportal&pivots=programming-language-csharp) to monitor changes on the `session` table.

Create a `local.settings.json` file from the provided `local.settings.json.sample` and add values for your enviroment for:

- AzureSQL.ConnectionString
- AzureOpenAI.Endpoint
- AzureOpenAI.Key

To upload the Azure Function code to Azure it is recommeded to use Visual Studio Code, and the [Azure Function extension](https://learn.microsoft.com/azure/azure-functions/functions-develop-vs-code?tabs=node-v3%2Cpython-v2%2Cisolated-process&pivots=programming-language-csharp): right click on the `/func` folder, select "Deploy to Function App" and then select the function app that has was created in 'Deploy Static Web App and Azure Function' step.

Another option is to use AZ CLI. First build the function:

```bash
cd func
dotnet publish
```

and then compress the content of the `publish` folder (sample for PowerShell):

```powershell
Compress-Archive .\bin\Debug\net6.0\publish\* SessionProcessor.zip
```

and the depoy it via AZ CLI:

```bash
az functionapp deploy --clean true --src-path .\SessionProcessor.zip -g <resource-group> -n <function-app-name>
```

After the function has been deployed, use VS Code to sync the `local.settings.json` with the deployed Azure Functions or create the enviroment variables

- AzureSQL.ConnectionString
- AzureOpenAI.Endpoint
- AzureOpenAI.Key

in the deployed Azure Function manually.

> Note: Azure function must be deployed as a stand-alone resource and cannot be deployed as a managed function within the Static Web App. Static Web Apps managed functions only support HTTP triggers.

## Test the solution

Add a new row to the `Sessions` table using the following SQL statement:

```sql
insert into web.sessions 
    (title, abstract)
values
    ('Building a session recommender using OpenAI and Azure SQL', 'In this fun and demo-driven session you’ll learn how to integrate Azure SQL with OpenAI to generate text embeddings, store them in the database, index them and calculate cosine distance to build a session recommender. And once that is done, you’ll publish it as a REST and GraphQL API to be consumed by a modern JavaScript frontend. Sounds pretty cool, uh? Well, it is!')
```

immediately the deployed Azure Function will get executed in response to the `INSERT` statement. The Azure Function will call the OpenAI service to generate the text embedding for the session title and abstract, and then store the embedding in the database, specifically in the `web.session_abstract_embeddings` table.

```sql
select * from web.session_abstract_embeddings
```

You can now open the URL associated with the created Static Web App to see the session recommender in action. You can get the URL from the Static Web App overview page in the Azure portal.

![Website running](./_docs/session-recommender.png)

## Run the solution locally

The whole solution can be executed locally, using [Static Web App CLI](https://github.com/Azure/static-web-apps-cli) and [Azure Function CLI](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Cisolated-process%2Cnode-v4%2Cpython-v2%2Chttp-trigger%2Ccontainer-apps&pivots=programming-language-csharp).

```bash
swa start --app-location ./client --data-api-location .\swa-db-connections\
```
