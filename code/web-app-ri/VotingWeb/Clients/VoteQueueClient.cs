// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Azure.ServiceBus;
using VotingWeb.Exceptions;
using VotingWeb.Interfaces;

namespace VotingWeb.Clients
{
    public class VoteQueueClient : IVoteQueueClient
    {
        private readonly IQueueClient queueClient;

        public VoteQueueClient(string connectionString, string queueName)
        {
            try
            {
                queueClient = new QueueClient(connectionString, queueName);
            }
            catch (Exception ex) when (ex is ArgumentException ||
                              ex is ServiceBusException ||
                              ex is UnauthorizedAccessException ||
                              ex is ArgumentNullException)
            {
                throw new VoteQueueException("Initialization Error for service bus", ex);
            }
        }

        public async Task SendVoteAsync(int id)
        {
            var messageBody = new { Id = id };

            try
            {
                var message = new Message(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(messageBody)))
                {
                    ContentType = "application/json",
                };

                await queueClient.SendAsync(message);
            }
            catch (Exception ex) when (ex is ArgumentException ||
                                 ex is ServiceBusException ||
                                 ex is UnauthorizedAccessException ||
                                 ex is ServerBusyException ||
                                 ex is ServiceBusTimeoutException)
            {
                throw new VoteQueueException("Service Bus Exception occurred with sending message to queue", ex);
            }
        }
    }
}