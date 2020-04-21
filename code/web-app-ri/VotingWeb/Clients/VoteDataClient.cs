// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using VotingWeb.Exceptions;
using VotingWeb.Interfaces;
using VotingWeb.Models;

namespace VotingWeb.Clients
{
    public class VoteDataClient : IVoteDataClient
    {
        private readonly HttpClient httpClient;

        public VoteDataClient(HttpClient httpClient)
        {
            this.httpClient = httpClient;
        }

        public async Task<IList<Counts>> GetCountsAsync()
        {
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Get, $"/api/VoteData");
                var response = await httpClient.SendAsync(request);
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsAsync<IList<Counts>>();
            }
            catch (Exception ex) when (ex is ArgumentNullException ||
                                 ex is InvalidOperationException ||
                                 ex is HttpRequestException)
            {
                throw new VoteDataException("Http Request Exception Occurred when getting votes", ex);
            }
        }

        public async Task<HttpResponseMessage> AddVoteAsync(string candidate)
        {
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Put, $"/api/VoteData/{candidate}");
                return await httpClient.SendAsync(request);
            }
            catch (Exception ex) when (ex is ArgumentNullException ||
                              ex is InvalidOperationException ||
                              ex is HttpRequestException)
            {
                throw new VoteDataException("Http Request Exception Occurred when adding vote", ex);
            }
        }

        public async Task DeleteCandidateAsync(string candidate)
        {
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Delete, $"/api/VoteData/{candidate}");
                var response = await httpClient.SendAsync(request);
                response.EnsureSuccessStatusCode();
            }
            catch (Exception ex) when (ex is ArgumentNullException ||
                          ex is InvalidOperationException ||
                          ex is HttpRequestException)
            {
                throw new VoteDataException("Http Request Exception Occurred when deleting vote", ex);
            }
        }
    }
}