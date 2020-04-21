// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System.Threading.Tasks;

namespace VotingWeb.Interfaces
{
    public interface IVoteQueueClient
    {
        Task SendVoteAsync(int id);
    }
}
