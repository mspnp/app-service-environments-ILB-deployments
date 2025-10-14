using Azure.Core;
using Azure.Identity;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System.Security;
using System.Text.Json;

namespace VoteCounter
{
    public class VoteCounter
    {
        private const string SqlDatabaseResourceUrl = "https://database.windows.net/";
        private readonly ILogger<VoteCounter> _logger;

        public VoteCounter(ILogger<VoteCounter> logger)
        {
            _logger = logger;
        }

        [Function(nameof(VoteCounter))]
        public async Task Run(
            [ServiceBusTrigger("votingqueue", Connection = "ServiceBusConnection")] string myQueueItem,
            FunctionContext context)
        {
            var vote = JsonSerializer.Deserialize<Vote>(myQueueItem);

            try
            {
                var connectionString = Environment.GetEnvironmentVariable("sqldb_connection");

                var credential = new DefaultAzureCredential();
                var tokenRequestContext = new TokenRequestContext(new[] { SqlDatabaseResourceUrl });
                var accessToken = await credential.GetTokenAsync(tokenRequestContext);

                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.AccessToken = accessToken.Token;
                    await conn.OpenAsync();

                    var text = "UPDATE dbo.Counts SET Count = Count + 1 WHERE ID = @ID;";
                    using (SqlCommand cmd = new SqlCommand(text, conn))
                    {
                        cmd.Parameters.AddWithValue("@ID", vote.Id);
                        var rows = await cmd.ExecuteNonQueryAsync();

                        if (rows == 0)
                        {
                            _logger.LogError("ID entry not found in the database: {id}", vote.Id);
                        }
                    }
                }
            }
            catch (Exception ex) when (ex is ArgumentNullException || ex is SecurityException || ex is SqlException)
            {
                _logger.LogError(ex, "SQL Exception occurred.");
            }
        }

        private class Vote
        {
            public int Id { get; set; }
        }

    }
}
