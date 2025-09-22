// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System.Data.Common;
using System.Threading;
using System.Threading.Tasks;
using Azure.Core;
using Azure.Identity;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace VotingData.Data
{
    public class AppServiceIdentityInterceptor : DbConnectionInterceptor
    {

        private static readonly TokenCredential _credential = new DefaultAzureCredential();
        private const string SqlDatabaseResourceUrl = "https://database.windows.net/";

        public override async ValueTask<InterceptionResult> ConnectionOpeningAsync(DbConnection connection, ConnectionEventData eventData, InterceptionResult result, CancellationToken cancellationToken = default)
        {  
            var sqlConnection = (SqlConnection)connection;

            var tokenRequestContext = new TokenRequestContext(new[] { SqlDatabaseResourceUrl });
            var accessToken = await _credential.GetTokenAsync(tokenRequestContext, cancellationToken);

            sqlConnection.AccessToken = accessToken.Token;


            return await base.ConnectionOpeningAsync(connection, eventData, result, cancellationToken);
        }
    }
}
