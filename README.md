# Session Recommender Sample

![Architecture Diagram](./_docs/session-recommender-architecture.png)

A session recommender built using

- Azure Static Web Apps
- Azure OpenAI
- Azure Functions
- Azure SQL Database
- Data API builder

## Getting Started

Make sure you have [AZ CLI installed](https://learn.microsoft.com/en-us/cli/azure/). It is also recommeneded to use VS Code with the Azure Functions extension installed.

### Create the resource group

Create a new resource group using the following command:

```bash
az group create -g <your-resource-group-name> -l <location>
```

### Create the Azure OpenAI service

Create a new [Azure OpenAI service](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=cli) in the resource group created in the previous step using the following command:

```bash
az cognitiveservices account create --name <your-openai-name> --resource-group <your-resource-group-name> --kind OpenAI --sku s0
```

Create an [embedding model](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#embeddings-models) using the [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=web-portal) and name it `embeddings`. Make sure to use the `text-embedding-ada-002` mode. Once the resource is created, and add the API key and the API url into the `.env` file.

### Deploy the solution

Fork this repository and then clone the forked respository locally.

#### Deploy the database

Create an new [Azure SQL database](https://learn.microsoft.com/en-us/azure/azure-sql/database/single-database-create-quickstart?view=azuresql&tabs=azure-portal), then run the `./database/setup-database.sql` script to set up the database.

It is recommened to use Azure Data Studio to run the script. Make sure that the `SQLCMD` mode is enabled. To enable `SQLCMD` mode, click on the `SQLCMD` button in the toolbar.

Before running the script set the values for the SQLCMD variable on top of the script:

```
:setvar OpenAIUrl https://<your-openai-service>.openai.azure.com
:setvar OpenAIKey <your-key>
```

using the value from the OpenAI service created in the previous step.

Then run the script to create the database.

#### Deploy Static Web App and Azure Function

Create a new `azuredeploy.parameter.json` file using the `azuredeploy.parameter.json.sample` file as a template. 

Replace the placeholders values in the newly created file with the correct values for your environment. Follow the documentation here: [Managing your personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) to get the GitHub token needed to deploy the Static Web App. Make sure the token created is a "classic" token that has access to the following scopes: **repo, workflow, write:packages**

Then run the following command to deploy the database to Azure. 

```bash
az deployment group create --resource-group <your-resource-group-name> --template-file main.bicep --parameters azuredeploy.parameters.json
```

#### Configure the Static Web App 

Now that the Static Web App has been deployed, it needs to be linked the Static Web App to the created database using the [Database Connections](https://learn.microsoft.com/en-us/azure/static-web-apps/database-overview) feature. Follow the instructions in the [Configure database connectivity](https://learn.microsoft.com/en-us/azure/static-web-apps/database-configuration#configure-database-connectivity) to configure the database connection.

#### Deploy the Azure Function

To upload the Azure Function code to Azure it is recommeded to use Visual Studio Code, and the Azure Function extension: right click on the `/func` folder, select "Deploy to Function App" and then select the function app that has was created in 'Deploy Static Web App and Azure Function' step.

> Note: Azure function must be deployed as a stand-alone resource and cannot be deployed managed function within the Static Web App. Static Web Apps managed functions only support HTTP triggers.

### Test the solution

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