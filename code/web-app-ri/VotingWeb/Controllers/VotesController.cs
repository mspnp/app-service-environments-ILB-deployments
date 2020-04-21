// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using VotingWeb.Exceptions;
using VotingWeb.Interfaces;

namespace VotingWeb.Controllers
{
    [Produces("application/json")]
    [Route("api/[controller]")]
    public class VotesController : Controller
    {
        private readonly ILogger<VotesController> logger;
        private readonly IVoteDataClient client;
        private readonly IVoteQueueClient queueClient;
        private readonly IAdRepository repositoryClient;

        public VotesController(IVoteDataClient client,
                               IVoteQueueClient queueClient,
                               ILogger<VotesController> logger,
                               IAdRepository repositoryClient)
        {
            this.client = client;
            this.queueClient = queueClient;
            this.logger = logger;
            this.repositoryClient = repositoryClient;
        }

        [HttpGet("")]
        public async Task<IActionResult> Get()
        {
            try
            {
                return this.Json(await this.client.GetCountsAsync());
            }
            catch (Exception ex) when (ex is VoteDataException)
            {
                logger.LogError(ex, "Exception getting the Votes from Database");
                return BadRequest("Bad Request");
            }
        }

        [HttpPut("{name}")]
        [Route("[action]/{name}")]
        public async Task<IActionResult> Add(string name)
        {
            try
            {
                var response = await this.client.AddVoteAsync(name);
                if (response.IsSuccessStatusCode)
                {
                    return this.Ok();
                }

                var errorMessage = await response.Content.ReadAsStringAsync();
                return BadRequest(errorMessage);
            }
            catch (Exception ex) when (ex is VoteDataException)
            {
                logger.LogError(ex, "Exception creating vote in database");
                return BadRequest("Bad Request");
            }
        }

        [HttpPut("{id}")]
        [Route("[action]/{id}")]
        public async Task<IActionResult> Vote(int id)
        {
            try
            {
                await queueClient.SendVoteAsync(id);
                return this.Ok();
            }
            catch (Exception ex) when (ex is VoteQueueException)
            {
                logger.LogError(ex, "Exception sending vote to the queue");
                return BadRequest("Bad Request");
            }
        }

        [HttpDelete("{name}")]
        public async Task<IActionResult> Delete(string name)
        {
            try
            {
                await this.client.DeleteCandidateAsync(name);
                return this.Ok();
            }
            catch (Exception ex) when (ex is VoteDataException)
            {
                logger.LogError(ex, "Exception deleting the vote from Database");
                return BadRequest("Bad Request");
            }
        }

        [HttpGet("{cache}")]
        public async Task<IActionResult> Cache()
        {
            try
            {
                return this.Json(await this.repositoryClient.GetAdsAsync());
            }
            catch (Exception ex) when (ex is AdRepositoryException)
            {
                logger.LogError(ex, "Exception getting ads from cache");
                return BadRequest("Bad Request");
            }
        }
    }
}