// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;
using System.Data.SqlClient;
using System.Security;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace FunctionApp
{
    public static class VoteCounter
    {
        private const string SqlDatabaseResourceUrl = "https://database.windows.net/";

        [FunctionName("VoteCounter")]
        public static async Task Run(
            [ServiceBusTrigger("votingqueue", Connection = "SERVICEBUS_CONNECTION_STRING")]string myQueueItem,
            ILogger log)
        {
            var vote = JsonSerializer.Deserialize<Vote>(myQueueItem);

            try
            {
                var connectionString = Environment.GetEnvironmentVariable("sqldb_connection");
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.AccessToken = await new AzureServiceTokenProvider().GetAccessTokenAsync(SqlDatabaseResourceUrl);

                    conn.Open();

                    var text = "UPDATE dbo.Counts  SET Count = Count + 1 WHERE ID = @ID;";

                    using (SqlCommand cmd = new SqlCommand(text, conn))
                    {
                        cmd.Parameters.AddWithValue("@ID", vote.Id);

                        var rows = await cmd.ExecuteNonQueryAsync();
                        if (rows == 0)
                        {
                            log.LogError("id entry not found on the database {id}", vote.Id);
                        }
                    }
                }
            }
            catch (Exception ex) when (ex is ArgumentNullException ||
                                    ex is SecurityException ||
                                    ex is SqlException)
            {
                log.LogError(ex, "Sql Exception");
            }
        }

        private class Vote
        {
            public int Id { get; set; }
        }
    }
}
