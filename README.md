# Enterprise SSO Architecture — Multi-Tenant Keycloak + OAuth2-Proxy Gateway

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.28%2B-blue.svg)](https://kubernetes.io/)
[![Keycloak](https://img.shields.io/badge/Keycloak-v24.0-red.svg)](https://www.keycloak.org/)
[![OAuth2--Proxy](https://img.shields.io/badge/OAuth2--Proxy-v7.6-purple.svg)](https://oauth2-proxy.github.io/oauth2-proxy/)
[![Security](https://img.shields.io/badge/Zero--Trust-Enforced-success.svg)](https://www.cisa.gov/zero-trust-maturity-model)

A centralized, production-grade Single Sign-On (SSO) and Identity Provider (IdP) platform using **Keycloak (OIDC/OAuth2/SAML)** and an **OAuth2-Proxy sidecar / forward-auth gateway** to protect modern and legacy workloads across 10+ internal services.

---

## Architecture Overview

```
                          [ Public / VPN Ingress (Traefik / NGINX) ]
                                            |
                                  TLS Termination (HTTPS)
                                            |
                    +-----------------------+-----------------------+
                    |                                               |
           Direct OIDC Workloads                         Legacy & Non-OIDC Services
                    |                                               |
         [ Native OIDC Clients ]                         [ OAuth2-Proxy Gateway ]
     (Argo CD, Grafana, Gitea, etc.)                     (ForwardAuth / Sidecar)
                    |                                               |
                    +-----------------------+-----------------------+
                                            |
                                   Token Validation & MFA
                                            v
                             [ Keycloak Identity Provider ]
                                   (Quarkus Runtime)
                                            |
                                            +---> [ PostgreSQL StatefulSet ]
                                            +---> [ HashiCorp Vault / ESO ]
                                            +---> [ LDAP / Active Directory ]
```

---

## Key Capabilities

1. **Centralized Multi-Tenant Identity Provider**:
   - Deployed **Keycloak 24** on Quarkus runtime with high-availability replication, dedicated PostgreSQL storage, and health probes (`/health/ready`, `/health/live`).
   - Declarative realm provisioning via [`keycloak/realms/enterprise-realm.json`](keycloak/realms/enterprise-realm.json) defining clients, scopes, claim mappers, and RBAC groups (`/PlatformAdmins`, `/PlatformEngineers`, `/Developers`).
   - Standard OIDC / OAuth2 endpoints for modern cloud-native applications.

2. **OAuth2-Proxy Sidecar & ForwardAuth Gateway**:
   - Transparent authentication gateway enabling SSO across legacy services without application source code modification.
   - **Sidecar Pattern**: Demonstrated in [`oauth2-proxy/03-oauth2-proxy-sidecar-pattern.yaml`](oauth2-proxy/03-oauth2-proxy-sidecar-pattern.yaml), intercepting pod traffic and forwarding authenticated requests to local application runtimes.
   - **ForwardAuth Gateway**: Ingress middleware integration in [`oauth2-proxy/04-ingress-forwardauth.yaml`](oauth2-proxy/04-ingress-forwardauth.yaml) enforcing authentication before requests reach internal services (Prometheus, Alertmanager, Longhorn, Hubble).

3. **Secure Session & Credential Escrow**:
   - AES-256-GCM encrypted cookie secrets with strict browser flags (`cookie_secure = true`, `cookie_httponly = true`, `cookie_samesite = "lax"`).
   - Automated secret synchronization using HashiCorp Vault and External Secrets Operator (ESO) in [`security-vault/oauth2-proxy-vault-secret.yaml`](security-vault/oauth2-proxy-vault-secret.yaml).
   - Automated TLS certificate lifecycle with `cert-manager` Let's Encrypt / internal CA.

---

## Directory Structure

```text
├── README.md
├── keycloak/
│   ├── 01-postgres-db.yaml                 # PostgreSQL backend StatefulSet & PVC
│   ├── 02-keycloak-deployment.yaml         # Keycloak HA Deployment with Quarkus
│   ├── 03-keycloak-ingress.yaml            # Traefik Ingress with TLS termination
│   └── realms/
│       └── enterprise-realm.json           # Declarative multi-tenant realm export
├── oauth2-proxy/
│   ├── 01-oauth2-proxy-config.yaml         # OAuth2-Proxy ConfigMap settings
│   ├── 02-oauth2-proxy-deployment.yaml     # Standalone OAuth2-Proxy gateway
│   ├── 03-oauth2-proxy-sidecar-pattern.yaml# Pod-level sidecar for legacy apps
│   ├── 04-ingress-forwardauth.yaml         # Traefik / NGINX Ingress integration
│   └── apps-sso-matrix.md                  # SSO matrix for 10+ self-hosted apps
└── security-vault/
    ├── config.hcl                          # Vault server configuration
    ├── vault-eso-integration.yaml          # ClusterSecretStore configuration
    └── oauth2-proxy-vault-secret.yaml      # ExternalSecret synchronization
```

---

## Deployment & Verification

### 1. Provision Keycloak & Storage
```bash
kubectl apply -f keycloak/01-postgres-db.yaml
kubectl apply -f keycloak/02-keycloak-deployment.yaml
kubectl apply -f keycloak/03-keycloak-ingress.yaml
```

### 2. Deploy OAuth2-Proxy & Ingress Middleware
```bash
kubectl apply -f oauth2-proxy/01-oauth2-proxy-config.yaml
kubectl apply -f oauth2-proxy/02-oauth2-proxy-deployment.yaml
kubectl apply -f oauth2-proxy/04-ingress-forwardauth.yaml
```

### 3. Verify Health & SSO Flow
```bash
# Check Keycloak ready status
kubectl get pods -n identity -l app=keycloak

# Verify OAuth2-Proxy health check
curl -fsS https://auth.enterprise.internal/ping
```
