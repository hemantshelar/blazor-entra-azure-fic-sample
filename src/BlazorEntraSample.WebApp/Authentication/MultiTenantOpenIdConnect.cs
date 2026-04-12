using BlazorEntraSample.WebApp.Options;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.Extensions.Options;
using Microsoft.Identity.Web;

namespace BlazorEntraSample.WebApp.Authentication;

internal static class MultiTenantOpenIdConnect
{
    public static void ChainTenantValidation(WebApplicationBuilder builder)
    {
        builder.Services.AddOptions<MultiTenantOptions>()
            .Bind(builder.Configuration.GetSection(MultiTenantOptions.SectionName));

        builder.Services.PostConfigure<OpenIdConnectOptions>(OpenIdConnectDefaults.AuthenticationScheme, options =>
        {
            var previous = options.Events.OnTokenValidated;
            options.Events.OnTokenValidated = async context =>
            {
                if (previous != null)
                {
                    await previous(context);
                }

                var multiTenant = context.HttpContext.RequestServices
                    .GetRequiredService<IOptions<MultiTenantOptions>>().Value;

                if (!multiTenant.Enabled)
                {
                    return;
                }

                var tid = context.Principal?.FindFirst(ClaimConstants.Tid)?.Value
                    ?? context.Principal?.FindFirst("tid")?.Value;

                if (string.IsNullOrEmpty(tid))
                {
                    context.Fail("Missing tenant id (tid) claim.");
                    return;
                }

                if (multiTenant.AllowedTenantIds.Count > 0 && !multiTenant.AllowedTenantIds.Contains(tid))
                {
                    context.Fail("This tenant is not allowed to sign in.");
                }
            };
        });
    }
}
