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
