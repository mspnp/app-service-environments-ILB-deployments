// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;

namespace VotingWeb.Exceptions
{
    public class VoteQueueException : Exception
    {
        public VoteQueueException(string message)
            : base(message)
        {
        }

        public VoteQueueException(string message, Exception inner)
            : base(message, inner)
        {
        }
    }
}
