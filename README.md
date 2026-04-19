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

### Using SQLite
```yaml
database:
  driver: sqlite
  
  sqlite:
    persistence:
      # If enabled is False, emptyDir will be used, data may be lost after Pod rebuild, it is recommended to use persistent volume
      enabled: true
      existingClaim: ""
      storageClass: ""
      accessMode: ReadWriteOnce
      size: 10Gi
```

When `persistence.enabled` is `false` use `emptyDir`,
1. If has created `pvc`, Please change `persistence.enabled` to `true`, and change`existingClaim`to your `pvc` name.
2. If `persistence.enabled` is `true` but `existingClaim` is empty,if will create a new `pvc` by `accessMode` `storageClass` `size`

### Using MySQL / Postgres

```yaml
database:
  driver: mysql # or postgres
  
  mysql:
    dsn: "memos_user:password@tcp(db:3306)/memos?charset=utf8mb4&parseTime=True&loc=Local"
    existingSecret: ""
    # If it is empty, `database-dsn` key will be used.
    existingSecretKey: ""
```
Please refer to the Memos Configuration for the DSN value.

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
