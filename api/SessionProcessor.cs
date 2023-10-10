using System;
using System.Collections.Generic;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Microsoft.Azure.WebJobs.Extensions.Sql;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;
using Microsoft.Data.SqlClient;
using System.Data;
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
            var key = Environment.GetEnvironmentVariable("AzureOpenAI.Key");
            var endpoint = Environment.GetEnvironmentVariable("AzureOpenAI.Endpoint");

            httpClient = new HttpClient();
            httpClient.BaseAddress = new Uri(endpoint);
            httpClient.DefaultRequestHeaders.Add("api-key", key);
        }

        [FunctionName("SessionProcessor")]
        public static async Task Run(
            [SqlTrigger("[netconf2023].[sessions]", "AzureSQL.ConnectionString")]
            IReadOnlyList<SqlChange<Session>> changes,
            ILogger logger)
        {
            foreach(var change in changes)
            {
                //logger.LogInformation("SQL Changes: " + JsonConvert.SerializeObject(change));

                if (change.Operation == SqlChangeOperation.Delete) continue;

                var response = await httpClient.PostAsJsonAsync(
                    "/openai/deployments/embeddings/embeddings?api-version=2023-03-15-preview",
                    new { input = change.Item.Abstract }
                );

                response.EnsureSuccessStatusCode();

                var jd = await response.Content.ReadAsAsync<JObject>();
                //var jd = JObject.Parse(j);
                var e = jd.SelectToken("data[0].embedding");
                //var u = jd.SelectToken("usage");
                
                //Console.WriteLine($"{change.Item.Id}: {u}");

                using var conn = new SqlConnection(Environment.GetEnvironmentVariable("AzureSQL.ConnectionString"));
                await conn.ExecuteAsync(
                    "netconf2023.upsert_session_abstract_embeddings",
                    commandType: CommandType.StoredProcedure,
                    param: new
                    {
                        @session_id = change.Item.Id,
                        @embeddings = e.ToString()
                    });
            }
        }
    }
}
