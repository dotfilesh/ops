# Jellyfin: manual setup

Settings the repo can't apply, kept so a rebuild can redo them.

## [OIDC login](https://github.com/9p4/jellyfin-plugin-sso) through Authentik

Plugin repository:

```
https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json
```

- **Name of OID Provider:** `jellyfin`
- **OID Endpoint:** `https://auth.<public domain>/application/o/jellyfin`
- **OpenID Client ID** / **OID Secret:** copied from the Authentik application
- **Admin Roles:** `sh.dotfile.auth/admin` (group must exist in Authentik)
- **Enable Role-Based Folder Access:**
  - `xyz.hellsite.watch/access-libraries`
  - `sh.dotfile.auth/admin`
- **Role Claim:** `groups` (add the claim in Authentik)
- **Request Additional Scopes:** `["groups"]`
- **Do Not Validate OpenID Endpoints (Insecure)**
