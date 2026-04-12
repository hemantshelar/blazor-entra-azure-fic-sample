namespace BlazorEntraSample.WebApp.Options;

public sealed class MultiTenantOptions
{
    public const string SectionName = "MultiTenant";

    /// <summary>
    /// When true, validates the Entra <c>tid</c> claim against <see cref="AllowedTenantIds"/> (if non-empty).
    /// Configure Azure AD with a multi-tenant authority (e.g. TenantId <c>organizations</c> or <c>common</c>).
    /// </summary>
    public bool Enabled { get; set; }

    /// <summary>
    /// Allowed directory (tenant) IDs. If empty while <see cref="Enabled"/> is true, any tenant is allowed (use only for demos).
    /// </summary>
    public List<string> AllowedTenantIds { get; set; } = [];
}
