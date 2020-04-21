// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos;
using StackExchange.Redis;
using VotingWeb.Exceptions;
using VotingWeb.Interfaces;
using VotingWeb.Models;

namespace VotingWeb.Clients
{
    public class AdRepository : IAdRepository
    {
        private static CosmosClient client;
        private static Container container;
        private static IDatabase cache;
        const string databaseId = "cacheDB";
        const string containerId = "cacheContainer";

        public AdRepository(string cacheConnectionString,
                                string cosmosEndpointUri,
                                string cosmosKey)
        {
            try
            {
                Lazy<ConnectionMultiplexer> lazyConnection = GetLazyConnection(cacheConnectionString);
                cache = lazyConnection.Value.GetDatabase();
                client = new CosmosClient(cosmosEndpointUri, cosmosKey);
                container = client.GetDatabase(databaseId).GetContainer(containerId);
            }
            catch (Exception ex) when (ex is RedisConnectionException ||
                                      ex is RedisException)
            {
                throw new AdRepositoryException("Redis connection initialization error", ex);
            }
            catch (Exception ex) when (ex is CosmosException)
            {
                throw new AdRepositoryException("Cosmos initialization error", ex);
            }
        }

        private static Lazy<ConnectionMultiplexer> GetLazyConnection(string connectionString)
        {
            return new Lazy<ConnectionMultiplexer>(() =>
            {
                return ConnectionMultiplexer.Connect(connectionString);
            });
        }

        public async Task<IList<Ad>> GetAdsAsync()
        {
            var ads = new List<Ad>();

            try
            {
                var response = await cache.StringGetAsync("1").ConfigureAwait(false);

                if (String.IsNullOrEmpty(response))
                {
                    var sqlQueryText = "SELECT * FROM c WHERE c.MessageType = 'AD'";
                    var partitionKeyValue = "AD";

                    var queryDefinition = new QueryDefinition(sqlQueryText);
                    FeedIterator<Ad> feedIterator =
                        container.GetItemQueryIterator<Ad>(
                            queryDefinition,
                            requestOptions: new QueryRequestOptions { PartitionKey = new PartitionKey(partitionKeyValue) });

                    while (feedIterator.HasMoreResults)
                    {
                        FeedResponse<Ad> currentResultSet = await feedIterator.ReadNextAsync();
                        ads.AddRange(currentResultSet);
                    }

                    await cache.StringSetAsync("1", JsonSerializer.Serialize(ads.First()), TimeSpan.FromMinutes(10));
                }
                else
                {
                    ads.Add(JsonSerializer.Deserialize<Ad>(response));
                }
            }
            catch (Exception ex) when (ex is RedisConnectionException ||
                                       ex is RedisException ||
                                       ex is RedisCommandException ||
                                       ex is RedisServerException ||
                                       ex is RedisTimeoutException ||
                                       ex is CosmosException ||
                                       ex is TimeoutException)
            {
                throw new AdRepositoryException("Repository Connection Exception", ex);
            }

            return ads;
        }
    }
}
