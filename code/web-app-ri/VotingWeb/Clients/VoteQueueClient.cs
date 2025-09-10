// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Configuration;
using System;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using VotingWeb.Exceptions;
using VotingWeb.Interfaces;

namespace VotingWeb.Clients
{
    public class VoteQueueClient : IVoteQueueClient
    {
        private readonly ServiceBusSender _sender;

        public VoteQueueClient(ServiceBusClient client, IConfiguration config)
        {
            var queueName = config["ConnectionStrings:queueName"];
            _sender = client.CreateSender(queueName);
        }

        public async Task SendVoteAsync(int id)
        {
            var messageBody = new { Id = id };
            try
            {
                var message = new ServiceBusMessage(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(messageBody)))
                {
                    ContentType = "application/json",
                };
                await _sender.SendMessageAsync(message);
            }
            catch (Exception ex) when (ex is ArgumentException ||
                                               ex is UnauthorizedAccessException ||
                                               ex is ServiceBusException)
            {
                throw new VoteQueueException("Service Bus Exception occurred with sending message to queue", ex);
            }
        }
    }
}