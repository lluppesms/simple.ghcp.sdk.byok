namespace ManagedIdentity.Models;

public sealed record DemoRunResult(
    string Response,
    IReadOnlyList<AzureIdentityEvent> Events,
    string CurrentServerTime,
    string TokenExpiresOn,
    string TokenRefreshOn,
    TimeSpan Elapsed,
    string? Error = null);
