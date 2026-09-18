# SSO Integration Architecture Matrix (10+ Applications)

This matrix documents the authentication patterns across internal workloads, detailing whether applications utilize direct OpenID Connect (OIDC) integration or transparent protection via OAuth2-Proxy sidecars/forward-auth gateways.

| Application | Integration Pattern | Auth Layer | Protocol | RBAC Group Mapping |
| :--- | :--- | :--- | :--- | :--- |
| **Argo CD** | Direct Native OIDC | Keycloak | OIDC / JWT | `/PlatformAdmins` -> `role:admin`<br>`/Developers` -> `role:readonly` |
| **Grafana** | Direct Native OIDC | Keycloak | OIDC / OAuth2 | `/PlatformAdmins` -> `Admin`<br>`/PlatformEngineers` -> `Editor`<br>`/Developers` -> `Viewer` |
| **Gitea** | Direct Native OIDC | Keycloak | OIDC | `/PlatformAdmins` -> Admin<br>`/Developers` -> User |
| **MinIO Console** | Direct Native OIDC | Keycloak | OIDC / STS | Assumes `readwrite` or `readonly` policies via JWT claim mapper |
| **Backstage IDP** | Direct Native OIDC | Keycloak | OIDC | Identity token validation via discovery endpoint |
| **Prometheus UI** | Ingress ForwardAuth | OAuth2-Proxy | HTTP Reverse Proxy | Ingress middleware rejects non-authenticated requests |
| **Alertmanager UI** | Ingress ForwardAuth | OAuth2-Proxy | HTTP Reverse Proxy | Restricted to `/PlatformEngineers` and `/PlatformAdmins` |
| **Longhorn Storage** | Ingress ForwardAuth | OAuth2-Proxy | HTTP Reverse Proxy | Restricted to `/PlatformAdmins` |
| **Hubble UI (Cilium)**| Ingress ForwardAuth | OAuth2-Proxy | HTTP Reverse Proxy | Observability access for platform engineers |
| **Legacy Portal** | Pod-Level Sidecar | OAuth2-Proxy | Localhost Loopback | Legacy HTTP service without native auth headers |
| **Internal Wiki/Docs** | Ingress ForwardAuth | OAuth2-Proxy | HTTP Reverse Proxy | Universal read access for all company email domains |

---

## Pattern Comparison

```
1. Direct Native OIDC Flow:
   Browser ---> [ Ingress ] ---> [ Native App (e.g. Grafana) ]
                                      |
                               (OIDC Redirect / Token Exchange)
                                      v
                              [ Keycloak IdP ]

2. ForwardAuth Gateway Flow:
   Browser ---> [ Ingress ] ---> (ForwardAuth check) ---> [ OAuth2-Proxy ]
                     |                                           |
                     | (If 200 OK with identity headers)         v
                     +---------------------------------> [ Keycloak IdP ]
                     v
             [ Upstream App (e.g. Alertmanager) ]

3. Pod-Level Sidecar Flow:
   Browser ---> [ Ingress ] ---> [ Pod ]
                                   +-- [ Container 1: OAuth2-Proxy (Port 4180) ]
                                   |       | (Inspects _enterprise_sso cookie)
                                   |       v (Reverse proxy via 127.0.0.1:8080)
                                   +-- [ Container 2: Legacy App (Port 8080) ]
```
