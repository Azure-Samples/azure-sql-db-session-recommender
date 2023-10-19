using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;

namespace api
{
    public static class AuthenticationProcessor
    {
        [FunctionName("AuthenticationProcessor")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log)
        {            
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            
            string userDetails = data?.userDetails ?? string.Empty;

            var roles = new List<string> { "authenticated", "anonymous" };

            if (userDetails.EndsWith("@microsoft.com")) roles.Add("microsoft");        
            log.LogInformation($"User {userDetails} has roles {string.Join(",", roles)}");                

            return new OkObjectResult(new { roles });
        }
    }
}
