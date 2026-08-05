namespace ManagedIdentity.Services;

public class GHCP_SDK_Service
{
    private readonly IConfiguration _configuration;
    private readonly DefaultAzureCredential _credential;
    private readonly ILogger<GHCP_SDK_Service> _logger;

    public string ModelName => _configuration["Azure:ModelName"] ?? "gpt-5.6-luna";

    public string FoundryUrl => _configuration["Azure:FoundryResourceUrl"]?.TrimEnd('/') ?? string.Empty;

    public string Prompt => _configuration["Demo:Prompt"] ?? "What is 2 + 2?";

    public GHCP_SDK_Service(IConfiguration configuration, ILogger<GHCP_SDK_Service> logger)
    {
        _configuration = configuration;
        _logger = logger;

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

        string currentServerTime = Utilities.FormatCurrentServerTime(DateTimeOffset.UtcNow);

        AccessToken token = default;

        string scope = _configuration["Azure:TokenScope"] ?? "https://ai.azure.com/.default";
        string baseUrl = $"{FoundryUrl}/openai/v1";
        string model = ModelName;
        string prompt = Prompt;

        _logger.LogInformation("Run button clicked. Calling model {ModelName} on {FoundryUrl} with prompt: \"{Prompt}\".", model, FoundryUrl, prompt);

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

            AssistantMessageEvent? response = await session.SendAndWaitAsync(new MessageOptions { Prompt = prompt, }, cancellationToken: cancellationToken);

            DemoRunResult result = new(
                response?.Data?.Content ?? string.Empty,
                events,
                currentServerTime,
                Utilities.Format(token.ExpiresOn),
                Utilities.Format(token.RefreshOn),
                Stopwatch.GetElapsedTime(startTimestamp));

            _logger.LogInformation("Finished calling model {ModelName} on {FoundryUrl} with prompt: \"{Prompt}\" in {Elapsed}. CurrentTime={CurrentServerTime}; TokenExpiresOn={TokenExpiresOn}; TokenRefreshOn={TokenRefreshOn}; Response={Response}", model, FoundryUrl, prompt, result.Elapsed, result.CurrentServerTime, result.TokenExpiresOn, result.TokenRefreshOn, result.Response);

            return result;
        }
        catch (Exception ex)
        {
            DemoRunResult result = new(
                string.Empty,
                events,
                currentServerTime,
                Utilities.Format(token.ExpiresOn),
                Utilities.Format(token.RefreshOn),
                Stopwatch.GetElapsedTime(startTimestamp),
                ex.Message);

            (int? statusCode, string? serviceErrorCode) = Utilities.TryGetServiceErrorMetadata(ex);
            string innerExceptions = Utilities.FlattenInnerExceptions(ex);
            string securityHint = Utilities.GetSecurityHint(ex, statusCode);

            _logger.LogError(ex, "Failed calling model {ModelName} on {FoundryUrl} with prompt: \"{Prompt}\" in {Elapsed}. CurrentTime={CurrentServerTime}; TokenExpiresOn={TokenExpiresOn}; TokenRefreshOn={TokenRefreshOn}; Error={Error}; ExceptionType={ExceptionType}; StatusCode={StatusCode}; ServiceErrorCode={ServiceErrorCode}; SecurityHint={SecurityHint}; InnerExceptions={InnerExceptions}", model, FoundryUrl, prompt, result.Elapsed, result.CurrentServerTime, result.TokenExpiresOn, result.TokenRefreshOn, result.Error, ex.GetType().FullName, statusCode, serviceErrorCode, securityHint, innerExceptions);

            return result;
        }
    }
}
