using System.Text;
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
        if (ex is AuthenticationFailedException)
        {
            return "Azure authentication failed while acquiring a token. Verify tenant, managed identity client ID, and credential source settings.";
        }

        if (statusCode == StatusCodes.Status401Unauthorized)
        {
            return "401 Unauthorized from Foundry. Token may be invalid for the target resource or scope.";
        }

        if (statusCode == StatusCodes.Status403Forbidden)
        {
            return "403 Forbidden from Foundry. Managed identity is authenticated but likely missing required role assignments on the Foundry resource.";
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

    private static string GetAbbreviation(DateTimeOffset value) =>
        CentralTimeZoneInfo.IsDaylightSavingTime(value) ? "CDT" : "CST";
}
