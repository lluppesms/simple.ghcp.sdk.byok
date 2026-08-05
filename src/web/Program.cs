using ManagedIdentity.Components;
using ManagedIdentity.Services;
using System.Globalization;

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

// Some Linux container environments can surface an invalid culture value (for example "$"),
// which breaks interactive component serialization. Force a known-safe default early.
try
{
    _ = CultureInfo.CurrentCulture;
    _ = CultureInfo.CurrentUICulture;
}
catch (CultureNotFoundException)
{
    CultureInfo fallbackCulture = CultureInfo.GetCultureInfo("en-US");
    CultureInfo.DefaultThreadCurrentCulture = fallbackCulture;
    CultureInfo.DefaultThreadCurrentUICulture = fallbackCulture;
}

builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddSingleton<GHCP_SDK_Service>();

WebApplication app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler(errorApp =>
    {
        errorApp.Run(async context =>
        {
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "text/plain";
            await context.Response.WriteAsync("An unhandled error occurred.");
        });
    });
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.UseAntiforgery();
app.MapStaticAssets();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
