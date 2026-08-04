namespace ManagedIdentity.Models;

/// <summary>Single event captured from the Azure Identity SDK event source during a run.</summary>
public sealed record AzureIdentityEvent(string EventName, string Message);
