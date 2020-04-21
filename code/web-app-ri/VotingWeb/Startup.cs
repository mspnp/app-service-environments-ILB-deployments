// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
// ------------------------------------------------------------

using System;
using System.Net.Mime;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using VotingWeb.Clients;
using VotingWeb.Interfaces;

namespace VotingWeb
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddApplicationInsightsTelemetry();

            services.Configure<CookiePolicyOptions>(options =>
            {
                options.CheckConsentNeeded = context => true;
                options.MinimumSameSitePolicy = SameSiteMode.None;
            });

            services.AddControllersWithViews();

            services.AddSingleton<IVoteQueueClient>(s =>
                new VoteQueueClient(
                    Configuration.GetValue<string>("ConnectionStrings:sbConnectionString"),
                    Configuration.GetValue<string>("ConnectionStrings:queueName")));

            services.AddSingleton<IAdRepository>(s =>
                new AdRepository(
                    Configuration.GetValue<string>("ConnectionStrings:RedisConnectionString"),
                    Configuration.GetValue<string>("ConnectionStrings:CosmosUri"),
                    Configuration.GetValue<string>("ConnectionStrings:CosmosKey")));

            services.AddHttpClient<IVoteDataClient, VoteDataClient>(c =>
            {
                c.BaseAddress = new Uri(Configuration.GetValue<string>("ConnectionStrings:VotingDataAPIBaseUri"));

                c.DefaultRequestHeaders.Add(
                    Microsoft.Net.Http.Headers.HeaderNames.Accept,
                    MediaTypeNames.Application.Json);
            });

            var uriBuilder = new UriBuilder(Configuration.GetValue<string>("ConnectionStrings:VotingDataAPIBaseUri"))
            {
                Path = "/health"
            };

            services.AddHealthChecks()
                .AddUrlGroup(uriBuilder.Uri, timeout: TimeSpan.FromSeconds(15))
                .AddRedis(Configuration.GetValue<string>("ConnectionStrings:RedisConnectionString"));
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            app.UseForwardedHeaders(new ForwardedHeadersOptions
            {
                ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
            });

            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Home/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseStaticFiles();
            app.UseCookiePolicy();

            app.UseRouting();
            app.UseEndpoints(builder =>
            {
                builder.MapControllers();
                builder.MapControllerRoute(
                    name: "default",
                    pattern: "{controller=Home}/{action=Index}/{id?}");

                builder.MapHealthChecks("/health");
            });
        }
    }
}