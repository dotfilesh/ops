# Additional notes

Things which are not applied with the repo itself; taken for posterity

# [OIDC Login](https://github.com/9p4/jellyfin-plugin-sso) through Auth@Dotfile

```
https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json
```

- **Name of OID Provider:** `jellyfin`
- **OID Endpoint:** `https://auth.dotfile.sh/application/o/jellyfin`
- **OpenID Client ID**/**OID Secret** are copied from Authentik
- **Admin Roles:** `sh.dotfile.auth/admin`
  - Must be made in Authentik
- **Enable Role-Based Folder Access:**
  - `xyz.hellsite.watch/access-libraries`
  - `sh.dotfile.auth/admin` 
- **Role Claim:** `groups`
  - Must be made in authentik
- **Request Additional Scopes:** `["groups"]`
- **Do Not Validate OpenID Endpoints (Insecure)**