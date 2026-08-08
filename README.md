## Install Steps

example

```shell
helm install memos .
```

use custom `namespace` example

```shell
helm install memos -n app .
```

## Requirements

- Kubernetes 1.19+
- Helm 3.0+

## Configuration

### Image Configuration

The default image tag uses the chart's `appVersion`. To use a different version:

```yaml
image:
  tag: "0.25.2"  # Specify a different version
```

## Persistence

Edit `values.yaml`

```yaml
persistence:
  ## If enabled is False, emptyDir will be used, data may be lost after Pod rebuild, it is recommended to use persistent volume
  enabled: false
  storageClass: "local"
  existPersistClaim: ""
  accessMode: ReadWriteOnce
  size: 10Gi
```

when `enabled` is `false` use `emptyDir`,
1. If has created `pvc`, Please change `enabled` to `true`, and change`existPersistClaim`to your `pvc` name.
2. If `enabled` is `true` but `existPersistClaim` is empty,if will create a new `pvc` by `accessMode` `storageClass` `size`

## Database

Edit `values.yaml`

```yaml
database:
  driver: postgres
  existingSecret:
    name: memos-cluster-app
    key: fqdn-uri
```

[Databases](https://usememos.com/docs/configuration/database) configuration can be done with an existing secret (recommended) or by a `database.connectionString`.

## Application Configuration

Edit `values.yaml`

```yaml
settings:
  enabled: true
  general:
    {
      "key": "GENERAL",
      "generalSetting":
        {
          "disallowUserRegistration": false,
          "disallowPasswordAuth": false,
          "additionalScript": "",
          "additionalStyle": "",
          "weekStartDayOffset": 1,
          "disallowChangeUsername": false,
          "disallowChangeNickname": false,
        },
    }
```

when `enabled` is `true` the [configuration](https://usememos.com/docs/configuration/deployment-configuration) is generated in `/etc/secrets`.

All configuration resources are supported.

```yaml
settings:
  enabled: false
  general: {}
  idps: []
  storage: {}
  memo: {}
  notification: {}
  ai: {}
```

For OAuth2 identity provider use for example:

```yaml
settings:
  enabled: true
  idps:
    - name: primary-sso
      config:
        {
          "uid": "primary-sso",
          "name": "Company SSO",
          "type": "OAUTH2",
          "identifierFilter": "",
          "config": {
            "oauth2Config": {
              "clientId": "client-id",
              "clientSecret": "client-secret",
              "authUrl": "https://idp.example.com/oauth/authorize",
              "tokenUrl": "https://idp.example.com/oauth/token",
              "userInfoUrl": "https://idp.example.com/oauth/userinfo",
              "scopes": ["openid", "profile", "email"],
              "fieldMapping": {
                "identifier": "sub",
                "displayName": "name",
                "email": "email",
                "avatarUrl": "picture"
              }
            }
          }
        }
```

## Security

The chart includes secure defaults:
- Runs as non-root user (UID 1000)
- Drops all capabilities
- No privilege escalation allowed

## Resources

Default resource limits are configured. Adjust in `values.yaml` based on your workload:

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```
