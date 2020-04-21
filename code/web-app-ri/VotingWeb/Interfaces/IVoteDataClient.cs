// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using VotingWeb.Models;

namespace VotingWeb.Interfaces
{
    public interface IVoteDataClient
    {
        Task<IList<Counts>> GetCountsAsync();

        Task<HttpResponseMessage> AddVoteAsync(string candidate);

        Task DeleteCandidateAsync(string candidate);
    }
}
