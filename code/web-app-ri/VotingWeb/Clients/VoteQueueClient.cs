// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using VotingWeb.Interfaces;

namespace VotingWeb.Clients
{
    public class VoteQueueClient : IVoteQueueClient
    {
        private readonly ServiceBusSender _sender;

        private readonly ILogger<VoteQueueClient> _logger;

        public VoteQueueClient(ServiceBusClient client, IConfiguration config, ILogger<VoteQueueClient> logger)
        {
            var queueName = config["ConnectionStrings:queueName"];
            var sbnamespace = config["ConnectionStrings:sbNamespace"];
            logger.LogInformation("Queue {Queue} {Namespace}" , queueName, sbnamespace);
            _sender = client.CreateSender(queueName);
            _logger = logger;
        }

        public async Task SendVoteAsync(int id)
        {
            var messageBody = new { Id = id };
            var message = new ServiceBusMessage(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(messageBody)))
            {
                ContentType = "application/json",
            };
            _logger.LogInformation("Message {QueueMessage}", JsonSerializer.Serialize(messageBody));
            await _sender.SendMessageAsync(message);
        }
    }
}