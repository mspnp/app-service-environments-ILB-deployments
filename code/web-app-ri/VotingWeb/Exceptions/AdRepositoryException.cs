// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;

namespace VotingWeb.Exceptions
{
    public class AdRepositoryException : Exception
    {
        public AdRepositoryException(string message)
        : base(message)
        {
        }

        public AdRepositoryException(string message, Exception inner)
            : base(message, inner)
        {
        }
    }
}
