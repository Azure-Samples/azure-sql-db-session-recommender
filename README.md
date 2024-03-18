---
page_type: sample
languages:
- azdeveloper
- csharp
- sql
- tsql
- javascript
- html
- bicep
products:
- azure-functions
- azure-sql-database
- static-web-apps
- sql-server
- azure-sql-managed-instance
- azure-sqlserver-vm
- dotnet
- azure-openai
urlFragment: azure-sql-db-session-recommender
name: Session Recommender using Azure SQL DB, Open AI and Vector Search
description: Build a session recommender using Jamstack and Event-Driven architecture, using Azure SQL DB to store and search vectors embeddings generated using OpenAI
---
<!-- YAML front-matter schema: https://review.learn.microsoft.com/en-us/help/contribute/samples/process/onboarding?branch=main#supported-metadata-fields-for-readmemd -->

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

## Retrieval Augmented Generation (RAG)

An enhanced version of this sample, that also include Retrieval Augmented Generation (RAG), is available at this repository: https://github.com/Azure-Samples/azure-sql-db-session-recommender-v2. If you are new to similarity search and RAG, it is recommended to start with this repo and then move to the enhanced one.

# Deploy the sample using the Azure Developer CLI (azd) template

The Azure Developer CLI (`azd`) is a developer-centric command-line interface (CLI) tool for creating Azure applications.

## Prerequisites

- Install [AZD CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd).
- Install [.NET SDK](https://dotnet.microsoft.com/download).
- Install [Node.js](https://nodejs.org/download/).
- Install [SWA CLI](https://azure.github.io/static-web-apps-cli/docs/use/install#installing-the-cli).

## Install AZD CLI

You need to install it before running and deploying with the Azure Developer CLI.

### Windows

```powershell
powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
```

### Linux/MacOS

```bash
curl -fsSL https://aka.ms/install-azd.sh | bash
```

After logging in with the following command, you will be able to use azd cli to quickly provision and deploy the application.

## Authenticate with Azure

Make sure AZD CLI can access Azure resources. You can use the following command to log in to Azure:

```bash
azd auth login
```

## Initialize the template

Then, execute the `azd init` command to initialize the environment (You do not need to run this command if you already have the code or have opened this in a Codespace or DevContainer).

```bash
azd init -t Azure-Samples/azure-sql-db-session-recommender
```

Enter an environment name.

## Deploy the sample

Run `azd up` to provision all the resources to Azure and deploy the code to those resources.

```bash
azd up 
```

Select your desired `subscription` and `location`. Then choose a resource group or create a new resource group. Wait a moment for the resource deployment to complete, click the Website endpoint and you will see the web app page.

**Note**: Make sure to pick a region where all services are available like, for example, *West Europe* or *East US 2*

## GitHub Actions

Using the Azure Developer CLI, you can setup your pipelines, monitor your application, test and debug locally.

```bash
azd pipeline config
```

## Test the solution

Add a new row to the `Sessions` table using the following SQL statement (you can use tools like [Azure Data Studio](https://learn.microsoft.com/en-us/azure-data-studio/quickstart-sql-database) or [SQL Server Management Studio](https://learn.microsoft.com/en-us/azure/azure-sql/database/connect-query-ssms?view=azuresql) to connect to the database. No need to install them if you don't want. In that case you can use the [SQL Editor in the Azure Portal](https://learn.microsoft.com/en-us/azure/azure-sql/database/connect-query-portal?view=azuresql)):

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

Install the required node packages needed by the fronted:

```bash
cd client
npm install
```

once finished, create a `./func/local.settings.json` and `.env` starting from provided samples files, and fill out the settings using the correct values for your environment.

From the sample root folder run:

```bash
swa start --app-location ./client --data-api-location ./swa-db-connections/
```

## (Optional) Use a custom authentication provider with Static Web Apps

The folder `api` contains a sample function to customize the authentication process as described in the [Custom authentication in Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/authentication-custom?tabs=aad%2Cinvitations#configure-a-custom-identity-provider) article. The function will add any user with a `@microsoft.com` to the `microsoft` role. Data API builder can be configured to allow acceess to a certain API only to users with a certain role, for example:

```json
"permissions": [
    {
        "role": "microsoft",
        "actions": [{
            "action": "execute"
        }]
    }
]
```

This step is optional and is provided mainly as an example on how to use custom authentication with SWA and DAB. It is not used in the solution.
