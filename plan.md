# Blazor Entra sample — architecture plan

## 1. Repository layout

```text
repo/
├── src/
│   └── YourSolution.sln
│   └── YourBlazorWebApp/              # Blazor Web App, Interactive Server default
├── infra/
│   └── bicep/
│       ├── main.bicep
│       ├── modules/
│       │   ├── app-service.bicep      # Phase 1: App Service + plan
│       │   ├── container-apps.bicep   # Phase 2 (optional): migrate/add CA
│       │   ├── rbac.bicep
│       │   ├── managed-identity-cicd.bicep   # UAMI + FIC (or split)
│       │   └── monitoring.bicep
│       └── parameters/
│           ├── dev.bicepparam
│           └── prod.bicepparam
├── .github/workflows/
│   ├── ci.yml
│   └── deploy.yml
└── docs/                              # optional
```

## 2. Blazor + Entra ID

- **Hosting model:** **Blazor Web App** with **Interactive Server** as the default render mode (server-side UI via SignalR, ASP.NET Core host).
- **Phase A — Single tenant:** App registration: single tenant; config: `TenantId`, `ClientId`, instance; use **Microsoft.Identity.Web** on the same web app.
- **Phase B — Multi-tenant:** Change supported account types / authority; enforce **`tid`** and tenant isolation in app logic and data.

## 3. Azure runtime (phased)

**Phase 1 (initial)**

- Resource group per environment.
- **App Service Plan (Linux)** + **Web App** targeting **.NET** (Blazor Server host).
- **Application Insights** (recommended).
- **System-assigned (or user-assigned) managed identity** on the Web App for Key Vault / Azure APIs as needed (separate from CI UAMI).

**Phase 2 (later)**

- **Migrate or add Azure Container Apps** for the same app (containerized ASP.NET Core).
- Plan for **SignalR** if you scale Blazor Server to **multiple replicas** (e.g. **Azure SignalR Service** + correct configuration).
- Bicep evolves: new module(s) for Container Apps / ACR as you adopt them.

## 4. CI/CD identity: user-assigned managed identity + FIC

- **UAMI** for GitHub Actions; **no client secret**.
- **RBAC:** e.g. Contributor (or tighter) on deploy scope for the UAMI.
- **FIC** on the UAMI: issuer `https://token.actions.githubusercontent.com`, audience `api://AzureADTokenExchange`, **subject** matching GitHub `sub` (branch / environment / tag).
- **GitHub:** `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`; workflow `permissions: id-token: write`; `azure/login@v2`.
- **IaC:** UAMI + federated credentials can live in Bicep; subjects must match GitHub.

## 5. Pipeline flow

1. **CI:** build/test Blazor Web App; optional Bicep validate / what-if.
2. **Deploy:** OIDC login → deploy/upgrade **Bicep** → publish **Blazor Server** app to App Service (zip/deploy or slot). Later: build/push image and deploy to Container Apps when you switch that module.

## 6. Configuration

- **Pipeline:** OIDC only (no Entra secret for CI).
- **App:** App Service settings for Entra + URLs; optional Key Vault references with Web App managed identity.

## 7. Implementation order

1. Blazor Web App (Interactive Server) + single-tenant Entra locally.
2. Bicep: RG + App Service + settings + monitoring.
3. UAMI + RBAC + FIC + `deploy.yml`.
4. Harden: GitHub Environments, what-if, scale/readiness notes for SignalR if multi-instance.
5. Multi-tenant Entra + server-side tenant handling.
6. **Later:** Container Apps + container build in pipeline; add SignalR service in Bicep if needed for scale-out.

## 8. Resolved decisions

| Topic        | Choice                                      |
| ------------ | ------------------------------------------- |
| Blazor       | **Web App, Interactive Server**             |
| Compute path | **App Service first** → **Container Apps** later |
| IaC          | **Bicep**                                   |
| CI auth      | **UAMI + FIC** (GitHub OIDC), no secrets   |
