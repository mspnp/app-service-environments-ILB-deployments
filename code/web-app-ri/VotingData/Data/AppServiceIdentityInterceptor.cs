// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System.Data.Common;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace VotingData.Data
{
    public class AppServiceIdentityInterceptor : DbConnectionInterceptor
    {
        public override async ValueTask<InterceptionResult> ConnectionOpeningAsync(DbConnection connection, ConnectionEventData eventData, InterceptionResult result, CancellationToken cancellationToken = default)
        {
            const string SqlDatabaseResourceUrl = "https://database.windows.net/";

            var sqlConnection = (SqlConnection)connection;
            // sqlConnection.AccessToken = await new AzureServiceTokenProvider().GetAccessTokenAsync(SqlDatabaseResourceUrl);

            return await base.ConnectionOpeningAsync(connection, eventData, result, cancellationToken);
        }
    }
}
