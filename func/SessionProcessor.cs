using System;
using System.Collections.Generic;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Microsoft.Azure.WebJobs.Extensions.Sql;
using Microsoft.Azure.WebJobs.Extensions.Timers;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Net;
using Dapper;

namespace SessionRecommender.SessionProcessor
{
    public class Session
    {
        public int Id { get; set; }

        public string Title { get; set; }

        public string Abstract { get; set; }

        public override bool Equals(object obj)
        {
            if (obj is Session)
            {
                var that = obj as Session;
                return this.Id == that.Id && this.Title == that.Title && this.Abstract == that.Abstract;
            }
            return false;
        }

        public override int GetHashCode()
        {
            return this.Id.GetHashCode() ^ this.Title.GetHashCode() ^ this.Abstract.GetHashCode();
        }
    }

    public static class SessionProcessor
    {
        private static HttpClient httpClient;

        static SessionProcessor()
        {
            var keyVaultEndpoint = Environment.GetEnvironmentVariable("AZURE_KEY_VAULT_ENDPOINT");
            var key = "openai_key";
            if (!string.IsNullOrEmpty(keyVaultEndpoint))
            {
                var openAIKeyName = Environment.GetEnvironmentVariable("AZURE_OPENAI_KEY");
                var client = new SecretClient(vaultUri: new Uri(keyVaultEndpoint), credential: new DefaultAzureCredential());
                key = client.GetSecret(openAIKeyName).Value.Value;
            }
            else
            {
                key = Environment.GetEnvironmentVariable("AZURE_OPENAI_KEY");
            }
            
            var endpoint = Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT");

            httpClient = new HttpClient();
            httpClient.BaseAddress = new Uri(endpoint);
            httpClient.DefaultRequestHeaders.Add("api-key", key);
        }

        [FunctionName("SessionProcessor")]
        public static async Task RunOnSqlTrigger(
            [SqlTrigger("[web].[sessions]", "AZURE_SQL_CONNECTION_STRING")]
            IReadOnlyList<SqlChange<Session>> changes,
            ILogger logger)
        {
            logger.LogInformation("Detected: " + changes.Count + " change(s).");

            foreach (var change in changes)
            {
                if (change.Operation == SqlChangeOperation.Delete) continue;
                logger.LogInformation($"[{change.Item.Id}] Processing change for operation: " + change.Operation.ToString());

                var attempts = 0;
                var embeddingsReceived = false;
                while (attempts < 3)
                {
                    attempts++;

                    logger.LogInformation($"[{change.Item.Id}] Attempt {attempts} of 3 to get embeddings.");

                    var deploymentName = Environment.GetEnvironmentVariable("AZURE_OPENAI_DEPLOYMENT_NAME");
                    var requestUri = "/openai/deployments/" + deploymentName + "/embeddings?api-version=2023-03-15-preview";
                    var response = await httpClient.PostAsJsonAsync(
                        requestUri,
                        new { input = change.Item.Title + ':' + change.Item.Abstract }
                    );

                    if (response.StatusCode == HttpStatusCode.TooManyRequests)
                    {
                        var waitFor = response.Headers.RetryAfter.Delta.Value.TotalSeconds;
                        logger.LogInformation($"[{change.Item.Id}] OpenAI had too many requests. Waiting {waitFor} seconds.");                        
                        await Task.Delay(TimeSpan.FromSeconds(waitFor));
                        continue;
                    }

                    response.EnsureSuccessStatusCode();

                    var jd = await response.Content.ReadAsAsync<JObject>();
                    var e = jd.SelectToken("data[0].embedding");
                    if (e != null)
                    {
                        using var conn = new SqlConnection(Environment.GetEnvironmentVariable("AZURE_SQL_CONNECTION_STRING"));
                        await conn.ExecuteAsync(
                            "web.upsert_session_abstract_embeddings",
                            commandType: CommandType.StoredProcedure,
                            param: new
                            {
                                @session_id = change.Item.Id,
                                @embeddings = e.ToString()
                            });                           
                        embeddingsReceived = true;                            
                        logger.LogInformation($"[{change.Item.Id}] Done.");
                    } else {
                        logger.LogInformation($"[{change.Item.Id}] No embeddings received.");
                    }
                    
                    break;                 
                }
                if (!embeddingsReceived) {
                    logger.LogInformation($"[{change.Item.Id}] Failed to get embeddings.");
                }
            }
        }
    
        [FunctionName("KeepAlive")]
        public static void RunOnTimerTrigger(
            [TimerTrigger("0 */1 * * * *")] TimerInfo myTimer,
            ILogger logger)
            {
                // Needed until SQL Trigger is GA.
                logger.LogInformation("Keep Alive Signal");
            }        
    }
}
