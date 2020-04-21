// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;

namespace VotingWeb.Exceptions
{
    public class VoteDataException : Exception
    {
        public VoteDataException(string message)
            : base(message)
        {
        }

        public VoteDataException(string message, Exception inner)
            : base(message, inner)
        {
        }
    }
}
