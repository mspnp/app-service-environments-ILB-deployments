using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.ApplicationInsights;
using Microsoft.Net.Http.Headers;
using StackExchange.Redis;
using System;
using System.Net.Mime;
using VotingWeb.Clients;
using VotingWeb.Interfaces;

var builder = WebApplication.CreateBuilder(args);
var configuration = builder.Configuration;


// -------------------- Logging Configuration --------------------
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

if (builder.Environment.IsDevelopment())
{
    builder.Logging.AddDebug();
}

builder.Services.AddLogging(builder =>
{
    // Only Application Insights is registered as a logger provider
    builder.AddApplicationInsights(
        configureTelemetryConfiguration: (config) => config.ConnectionString = configuration["ApplicationInsights:ConnectionString"],
        configureApplicationInsightsLoggerOptions: (options) => { }
    );
});

builder.Logging.AddFilter<ApplicationInsightsLoggerProvider>("Microsoft", LogLevel.Trace);
builder.Logging.AddFilter<ApplicationInsightsLoggerProvider>("Microsoft", LogLevel.Warning);

// -------------------- Service Configuration --------------------
// Telemetry
builder.Services.AddApplicationInsightsTelemetry();

builder.Services.Configure<CookiePolicyOptions>(options =>
{
    options.CheckConsentNeeded = context => true;
    options.MinimumSameSitePolicy = Microsoft.AspNetCore.Http.SameSiteMode.None;
});

// MVC
builder.Services.AddControllersWithViews();

// Azure Service Bus
builder.Services.AddSingleton(sp =>
{
    var credential = new DefaultAzureCredential();
    return new ServiceBusClient(configuration["ConnectionStrings:sbNamespace"], credential);
});
builder.Services.AddSingleton<IVoteQueueClient, VoteQueueClient>();

// Cosmos DB
builder.Services.AddSingleton(sp =>
{
    var credential = new DefaultAzureCredential();
    return new CosmosClient(configuration["ConnectionStrings:CosmosUri"], credential);
});
builder.Services.AddSingleton<IAdRepository, AdRepository>();

// HTTP Client
builder.Services.AddHttpClient<IVoteDataClient, VoteDataClient>(c =>
{
    c.BaseAddress = new Uri(configuration["ConnectionStrings:VotingDataAPIBaseUri"]);
    c.DefaultRequestHeaders.Add(HeaderNames.Accept, MediaTypeNames.Application.Json);
});

var host = configuration["RedisHost"];
var port = configuration["RedisPort"];
var options = ConfigurationOptions.Parse($"{host}:{port}");
await options.ConfigureForAzureWithTokenCredentialAsync(new DefaultAzureCredential());
var redis = await ConnectionMultiplexer.ConnectAsync(options);

// Redis
builder.Services.AddSingleton<IConnectionMultiplexer>(redis);

builder.Services.AddSingleton(sp =>
{
    var multiplexer = sp.GetRequiredService<IConnectionMultiplexer>();
    return multiplexer.GetDatabase();
});

// Health Checks
var healthUri = new UriBuilder(configuration["ConnectionStrings:VotingDataAPIBaseUri"])
{
    Path = "/health"
}.Uri;

builder.Services.AddHealthChecks()
    .AddUrlGroup(healthUri, timeout: TimeSpan.FromSeconds(15));

var app = builder.Build();

// Forwarded Headers
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

// Error Handling
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseCookiePolicy();

app.UseRouting();

app.MapControllers();
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.MapHealthChecks("/health");

app.Run();
