// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System.Collections.Generic;
using System.Threading.Tasks;
using VotingWeb.Models;

namespace VotingWeb.Interfaces
{
    public interface IAdRepository
    {
        Task<IList<Ad>> GetAdsAsync();
    }
}