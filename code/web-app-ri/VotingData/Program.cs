// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.ApplicationInsights;

namespace VotingData
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host
                .CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                    webBuilder
                        .ConfigureLogging((hostingContext, logging) =>
                        {
                            if (hostingContext.HostingEnvironment.IsDevelopment())
                            {
                                logging.AddDebug();
                            }


                            var connectionString = hostingContext.Configuration["ApplicationInsights:ConnectionString"];

                            logging.AddApplicationInsights(
                                configureTelemetryConfiguration: config =>
                                {
                                    config.ConnectionString = connectionString;
                                },options => { }
                            );

                            logging.AddFilter<ApplicationInsightsLoggerProvider>("", LogLevel.Trace);
                            logging.AddFilter<ApplicationInsightsLoggerProvider>("Microsoft", LogLevel.Warning);
                        })
                        .UseStartup<Startup>());
    }
}
