using System.Diagnostics;
using System.Diagnostics.Tracing;
using Azure.Core;
using Azure.Core.Diagnostics;
using Azure.Identity;
using GitHub.Copilot;
using ManagedIdentity.Models;

namespace ManagedIdentity.Services;

public class GHCP_SDK_Service
{
    private static readonly TimeZoneInfo CentralTimeZoneInfo =
        TimeZoneInfo.FindSystemTimeZoneById(
            OperatingSystem.IsWindows() ? "Central Standard Time" : "America/Chicago");

    private readonly IConfiguration _configuration;
    private readonly DefaultAzureCredential _credential;

    public string ModelName => _configuration["Azure:ModelName"] ?? "gpt-5.4-nano";

    public string FoundryUrl => _configuration["Azure:FoundryResourceUrl"]?.TrimEnd('/') ?? string.Empty;

    public string Prompt => _configuration["Demo:Prompt"] ?? "What is 2 + 2?";

    public GHCP_SDK_Service(IConfiguration configuration)
    {
        _configuration = configuration;

        // Which credential is used comes from AZURE_TOKEN_CREDENTIALS (AzureCliCredential locally,
        // ManagedIdentityCredential in Azure) and AZURE_CLIENT_ID selects the user-assigned identity.
        _credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
        {
            TenantId = configuration["Azure:EntraTenantId"],
        });
    }

    public async Task<DemoRunResult> RunAsync(CancellationToken cancellationToken = default)
    {
        List<AzureIdentityEvent> events = [];

        using AzureEventSourceListener listener = new((eventArgs, message) =>
        {
            events.Add(new AzureIdentityEvent(eventArgs.EventName ?? "Unknown", message));
        }, level: EventLevel.Informational);

        DateTimeOffset currentServerTimeCentral =
            TimeZoneInfo.ConvertTime(DateTimeOffset.UtcNow, CentralTimeZoneInfo);
        string currentServerTime =
            $"{currentServerTimeCentral:f} ({GetAbbreviation(currentServerTimeCentral)})";

        AccessToken token = default;

        string scope = _configuration["Azure:TokenScope"] ?? "https://ai.azure.com/.default";
        string baseUrl = $"{FoundryUrl}/openai/v1";
        string model = ModelName;
        string prompt = Prompt;

        long startTimestamp = Stopwatch.GetTimestamp();

        try
        {
            await using CopilotClient client = new();
            await using CopilotSession session = await client.CreateSessionAsync(
                new SessionConfig
                {
                    Model = model,
                    Provider = new ProviderConfig
                    {
                        Type = "openai",
                        BaseUrl = baseUrl,
                        WireApi = "responses",
                        BearerTokenProvider = async _ =>
                        {
                            token = await _credential.GetTokenAsync(
                                new TokenRequestContext([scope]),
                                cancellationToken);
                            return token.Token;
                        },
                    },
                },
                cancellationToken);

            AssistantMessageEvent? response = await session.SendAndWaitAsync(
                new MessageOptions
                {
                    Prompt = prompt,
                },
                cancellationToken: cancellationToken);

            return new DemoRunResult(
                response?.Data?.Content ?? string.Empty,
                events,
                currentServerTime,
                Format(token.ExpiresOn),
                Format(token.RefreshOn),
                Stopwatch.GetElapsedTime(startTimestamp));
        }
        catch (Exception ex)
        {
            return new DemoRunResult(
                string.Empty,
                events,
                currentServerTime,
                Format(token.ExpiresOn),
                Format(token.RefreshOn),
                Stopwatch.GetElapsedTime(startTimestamp),
                ex.Message);
        }
    }

    private static string Format(DateTimeOffset? value)
    {
        if (value is null || value == default(DateTimeOffset))
        {
            return "—";
        }

        DateTimeOffset central = TimeZoneInfo.ConvertTime(value.Value, CentralTimeZoneInfo);
        return $"{central:f} ({GetAbbreviation(central)})";
    }

    private static string GetAbbreviation(DateTimeOffset value) =>
        CentralTimeZoneInfo.IsDaylightSavingTime(value) ? "CDT" : "CST";
}
