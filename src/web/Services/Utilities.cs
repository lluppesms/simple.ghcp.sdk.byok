using System.Text;
using System.Text.Json;
using Azure;
using Azure.Identity;
using Microsoft.AspNetCore.Http;

namespace ManagedIdentity.Services;

internal static class Utilities
{
    private static readonly TimeZoneInfo CentralTimeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById(
        OperatingSystem.IsWindows() ? "Central Standard Time" : "America/Chicago");

    public static (int? StatusCode, string? ServiceErrorCode) TryGetServiceErrorMetadata(Exception ex)
    {
        RequestFailedException? requestFailed = ex as RequestFailedException;

        if (requestFailed is null)
        {
            requestFailed = ex.InnerException as RequestFailedException;
        }

        return requestFailed is null
            ? (null, null)
            : (requestFailed.Status, requestFailed.ErrorCode);
    }

    public static string FlattenInnerExceptions(Exception ex)
    {
        StringBuilder builder = new();
        Exception? current = ex.InnerException;
        int depth = 1;

        while (current is not null)
        {
            if (builder.Length > 0)
            {
                builder.Append(" | ");
            }

            builder
                .Append('#')
                .Append(depth)
                .Append(' ')
                .Append(current.GetType().Name)
                .Append(": ")
                .Append(current.Message);

            current = current.InnerException;
            depth++;
        }

        return builder.Length == 0 ? "None" : builder.ToString();
    }

    public static string GetSecurityHint(Exception ex, int? statusCode)
    {
        string message = ex.Message;

        if (ex is AuthenticationFailedException)
        {
            return "Azure authentication failed while acquiring a token. Verify tenant, managed identity client ID, and credential source settings.";
        }

        if (statusCode == StatusCodes.Status401Unauthorized)
        {
            return "401 Unauthorized from Foundry. Token may be invalid for the target resource or scope.";
        }

        if (statusCode is null && message.Contains("HTTP 401", StringComparison.OrdinalIgnoreCase))
        {
            return "401 Unauthorized from Foundry (wrapped by SDK). Managed identity token was acquired but rejected by the inference endpoint. Verify role assignment on the Foundry/Cognitive Services account and confirm the endpoint and token audience are correct.";
        }

        if (statusCode == StatusCodes.Status403Forbidden)
        {
            return "403 Forbidden from Foundry. Managed identity is authenticated but likely missing required role assignments on the Foundry resource.";
        }

        if (statusCode is null && message.Contains("COPILOT_PROVIDER_BEARER_TOKEN", StringComparison.OrdinalIgnoreCase))
        {
            return "Provider reported bearer-token authentication failure. Ensure the request uses a valid Entra token for the Foundry endpoint and that the managed identity has data-plane access.";
        }

        return "No explicit security classification for this failure.";
    }

    public static string Format(DateTimeOffset? value)
    {
        if (value is null || value == default(DateTimeOffset))
        {
            return "-";
        }

        DateTimeOffset central = TimeZoneInfo.ConvertTime(value.Value, CentralTimeZoneInfo);
        return $"{central:f} ({GetAbbreviation(central)})";
    }

    public static string FormatCurrentServerTime(DateTimeOffset utcNow)
    {
        DateTimeOffset currentServerTimeCentral = TimeZoneInfo.ConvertTime(utcNow, CentralTimeZoneInfo);
        return $"{currentServerTimeCentral:f} ({GetAbbreviation(currentServerTimeCentral)})";
    }

    public static string GetJwtClaim(string jwt, string claimName)
    {
        if (string.IsNullOrWhiteSpace(jwt) || string.IsNullOrWhiteSpace(claimName))
        {
            return "n/a";
        }

        try
        {
            string[] parts = jwt.Split('.');
            if (parts.Length < 2)
            {
                return "unparseable";
            }

            byte[] payloadBytes = DecodeBase64Url(parts[1]);
            using JsonDocument doc = JsonDocument.Parse(payloadBytes);

            if (doc.RootElement.TryGetProperty(claimName, out JsonElement value))
            {
                return value.ValueKind == JsonValueKind.String
                    ? value.GetString() ?? "empty"
                    : value.ToString();
            }

            return "missing";
        }
        catch
        {
            return "unparseable";
        }
    }

    private static byte[] DecodeBase64Url(string input)
    {
        string normalized = input.Replace('-', '+').Replace('_', '/');
        int mod = normalized.Length % 4;

        if (mod == 2)
        {
            normalized += "==";
        }
        else if (mod == 3)
        {
            normalized += "=";
        }
        else if (mod != 0)
        {
            throw new FormatException("Invalid Base64Url payload length.");
        }

        return Convert.FromBase64String(normalized);
    }

    private static string GetAbbreviation(DateTimeOffset value) =>
        CentralTimeZoneInfo.IsDaylightSavingTime(value) ? "CDT" : "CST";
}
