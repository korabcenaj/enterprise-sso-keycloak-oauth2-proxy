# Enterprise SSO Architecture — Multi-Tenant Keycloak + OAuth2-Proxy Gateway

Zero-trust Single Sign-On (SSO) architecture leveraging Keycloak and OAuth2-Proxy sidecar proxies.

## Key Capabilities
- **Keycloak Identity Provider**: OIDC, OAuth2, and SAML multi-realm authentication with fine-grained RBAC.
- **OAuth2-Proxy Gateway**: Transparent SSO protection for legacy and internal applications without native OIDC support.
- **Vault & ESO Integration**: Automated PKI certificate management and secret synchronization.
