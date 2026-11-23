# Memos Helm chart

Memos is an open-source, self-hosted note-taking app for your everyday thoughts. It’s a place to write what’s on your mind as you go about your day. A single sentence can be a whole memo, or you can take your time with a longer entry, using Markdown to give your words more structure.

These moments of writing gradually become a personal record. Each memo stays with the day you wrote it, bringing your thoughts together in a timeline you can look back through. Tags connect related thoughts across those days, making it easy to pick up a topic again or find something you remember writing.

That record lives on your own server, and your data stays yours. You choose what stays private, what to share with family and friends, and what to publish on the web. In shared spaces, you can write alongside others while each person keeps their own memos.

This chart runs [Memos](https://github.com/usememos/memos) on Kubernetes.

## Install

```bash
helm install memos oci://ghcr.io/usememos/charts/memos --namespace memos --create-namespace
```

With the defaults you get one Memos pod using SQLite, a 10Gi volume for its data, and a `ClusterIP` service on port 5230. Reach it with a port-forward and create the first account:

```bash
kubectl port-forward service/memos 5230:5230 --namespace memos
```

Requirements: Kubernetes 1.25 or later, and Helm 3.8 or later (Helm 4 works too).

## What the chart sets up

| Resource | Notes |
| --- | --- |
| Deployment | The `ghcr.io/usememos/memos` image at the chart’s `appVersion`, as UID and GID 10001 with a read-only root filesystem and no capabilities |
| Service | Port 5230 by default |
| PersistentVolumeClaim | Mounted at `/var/opt/memos`; holds the SQLite database and locally stored attachments |
| ServiceAccount | Without a mounted token, because Memos does not call the Kubernetes API |
| Secret | Only when `database.dsn` is set |
| ConfigMap | Only when `config.files` is set |
| Ingress or HTTPRoute | Only when enabled |

The pod sets `MEMOS_PORT` itself and turns service links off, so a release named `memos` does not run into the [`MEMOS_PORT` collision](https://usememos.com/docs/deploy/kubernetes).

## Database

SQLite is the default and needs no settings. It supports one replica, and the chart replaces the pod instead of rolling it so two pods never open the same database file.

For PostgreSQL or MySQL, keep the connection string in a Secret you manage:

```bash
kubectl create secret generic memos-database --namespace memos \
  --from-literal=dsn='postgres://memos:password@postgres:5432/memos?sslmode=disable'
```

```yaml
database:
  driver: postgres
  existingSecret:
    name: memos-database
    key: dsn
```

A MySQL connection string has the form `user:password@tcp(host:3306)/memos`. You can also pass `database.dsn` directly and the chart stores it in a Secret, which is convenient for a trial but leaves the password in your values.

The chart does not install a database. The data volume is still used with an external database when attachments are stored on the local file system; turn it off with `persistence.enabled: false` once attachments live in the database or in object storage.

## Declarative configuration

Memos can take its instance settings, identity providers, and first administrator from JSON files instead of the admin UI. See [declarative configuration](https://usememos.com/docs/configuration/declarative-configuration) for the file format. Put the files under `config.files`, written as YAML, and reference secrets as `${env:NAME}`:

```yaml
instanceUrl: https://memos.example.com

config:
  files:
    instance.json:
      instanceSettings:
        - name: instance/settings/ACCESS
          accessSetting:
            accessMode: INSTANCE_ACCESS_MODE_PRIVATE
        - name: instance/settings/GENERAL
          generalSetting:
            disallowUserRegistration: true
      users:
        - name: users/admin
          username: admin
          role: ADMIN
          password: ${env:MEMOS_ADMIN_PASSWORD}
      lifecycle:
        - resource: users/admin
          preventDestroy: true
          writeOnlyVersion: 1

extraEnv:
  - name: MEMOS_ADMIN_PASSWORD
    valueFrom:
      secretKeyRef:
        name: memos-admin
        key: password
```

The chart renders each entry to a file in `/etc/memos/config`. Memos applies the files at startup, before it serves requests, and the chart restarts the pod whenever `config.files` changes. `config.existingConfigMap` and `config.existingSecret` add the keys of resources you manage to the same directory; restart the deployment yourself after changing those.

Set `config.apply: "off"` to apply only through `memos config apply`.

## Reaching Memos

Set `instanceUrl` to the address people use, then expose the service with an Ingress:

```yaml
instanceUrl: https://memos.example.com

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: memos.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: memos-tls
      hosts:
        - memos.example.com
```

Or with a Gateway API route:

```yaml
instanceUrl: https://memos.example.com

httpRoute:
  enabled: true
  parentRefs:
    - name: gateway
      namespace: gateway-system
  hostnames:
    - memos.example.com
```

Memos trusts forwarding headers from private address ranges by default, which covers an in-cluster proxy. Other `MEMOS_*` [environment variables](https://usememos.com/docs/configuration/environment-variables) go in `extraEnv`.

## Your data

Everything Memos keeps on disk is in the volume mounted at `/var/opt/memos`. Back up that volume, and the external database if you use one.

The chart-managed claim carries `helm.sh/resource-policy: keep`, so `helm uninstall` leaves it in place. Installing the release again under the same name and namespace picks it back up. Delete the claim yourself when you no longer want the data, or set `persistence.retain: false`.

## Upgrading Memos

Each chart version defaults to one Memos release, shown as `appVersion`. Upgrade the chart to move to a newer release, or pin another one with `image.tag`. Memos migrates its database at startup, and the startup probe allows five minutes for it.

Coming from a Memos release before v0.31.0, run v0.31.0 once first; see the [upgrade requirements](https://github.com/usememos/memos/blob/main/store/migration/README.md).

## Upgrading from chart 0.2

Chart 1.0 renames several values and rejects the old names instead of ignoring them.

| 0.2 | 1.0 |
| --- | --- |
| `image.repo`, `image.imageName` | `image.repository` |
| `image.tag: latest` | Empty, which means the chart’s `appVersion` |
| `persistence.existPersistClaim` | `persistence.existingClaim` |
| `persistence.accessMode` | `persistence.accessModes` (a list) |
| `persistence.storageClass: local` | Empty, which means the cluster default |
| `persistence.enabled: false` | `true` |
| `autoscaling.*` | Removed; set `replicaCount` |
| `podSecurityContext`, `securityContext` with UID 1000 | UID and GID 10001, matching the image |

Before you upgrade a release that already has a claim, set `persistence.storageClass` to the class the claim was created with, since a claim’s storage class cannot change. If the release ran on an `emptyDir`, export your memos first: the old pod’s data does not move to the new volume.

Files written by the old UID stay readable because the pod’s `fsGroup` gives group 10001 access to the volume. On storage that ignores `fsGroup`, such as some NFS exports, change the owner of the files to 10001 yourself.

## Values

| Key | Default | Description |
| --- | --- | --- |
| `image.repository` | `ghcr.io/usememos/memos` | Image repository |
| `image.tag` | `""` | Image tag; defaults to the chart `appVersion` |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy |
| `imagePullSecrets` | `[]` | Pull secrets for private registries |
| `nameOverride`, `fullnameOverride` | `""` | Override the generated resource names |
| `replicaCount` | `1` | Number of pods; more than one needs MySQL or PostgreSQL |
| `instanceUrl` | `""` | Canonical external URL, set as `MEMOS_INSTANCE_URL` |
| `database.driver` | `sqlite` | `sqlite`, `mysql`, or `postgres` |
| `database.dsn` | `""` | Connection string, stored in a chart-managed Secret |
| `database.existingSecret.name` | `""` | Secret holding the connection string |
| `database.existingSecret.key` | `dsn` | Key of the connection string in that Secret |
| `config.apply` | `startup` | `startup` or `off` |
| `config.files` | `{}` | Declarative configuration files, keyed by a name ending in `.json` |
| `config.existingConfigMap` | `""` | ConfigMap added to the configuration directory |
| `config.existingSecret` | `""` | Secret added to the configuration directory |
| `extraEnv` | `[]` | Extra environment variables |
| `extraEnvFrom` | `[]` | Extra `envFrom` sources |
| `persistence.enabled` | `true` | Keep `/var/opt/memos` on a persistent volume |
| `persistence.existingClaim` | `""` | Use a claim you manage |
| `persistence.storageClass` | `""` | Storage class; empty uses the cluster default |
| `persistence.accessModes` | `[ReadWriteOnce]` | Access modes of the claim |
| `persistence.size` | `10Gi` | Size of the claim |
| `persistence.annotations` | `{}` | Annotations for the claim |
| `persistence.retain` | `true` | Keep the claim when the release is uninstalled |
| `serviceAccount.create` | `true` | Create a service account |
| `serviceAccount.automount` | `false` | Mount the service account token |
| `serviceAccount.annotations` | `{}` | Annotations for the service account |
| `serviceAccount.name` | `""` | Service account name |
| `podAnnotations`, `podLabels` | `{}` | Extra pod metadata |
| `podSecurityContext` | UID, GID, and `fsGroup` 10001 | Pod security context |
| `securityContext` | Read-only root, no capabilities | Container security context |
| `service.type` | `ClusterIP` | `ClusterIP`, `NodePort`, or `LoadBalancer` |
| `service.port` | `5230` | Service port |
| `service.nodePort` | `null` | Fixed node port |
| `service.annotations` | `{}` | Annotations for the service |
| `ingress.enabled` | `false` | Create an Ingress |
| `ingress.className` | `""` | Ingress class |
| `ingress.annotations` | `{}` | Annotations for the Ingress |
| `ingress.hosts` | `memos.example.com` at `/` | Hosts and paths |
| `ingress.tls` | `[]` | TLS configuration |
| `httpRoute.enabled` | `false` | Create a Gateway API `HTTPRoute` |
| `httpRoute.parentRefs` | `[]` | Gateways the route attaches to |
| `httpRoute.hostnames` | `[]` | Hostnames the route matches |
| `httpRoute.matches` | Path prefix `/` | Match rules |
| `httpRoute.annotations` | `{}` | Annotations for the route |
| `resources` | Requests of 50m CPU, 128Mi memory | Container resources |
| `startupProbe`, `livenessProbe`, `readinessProbe` | See `values.yaml` | Probes; `/healthz` answers only while the database does |
| `strategy` | `{}` | Update strategy; empty picks `Recreate` for SQLite or a data volume |
| `terminationGracePeriodSeconds` | `30` | Time allowed for shutdown |
| `priorityClassName` | `""` | Pod priority class |
| `nodeSelector`, `tolerations`, `affinity`, `topologySpreadConstraints` | Empty | Scheduling |
| `extraVolumes`, `extraVolumeMounts` | `[]` | Extra volumes and mounts |
| `tests.image.repository`, `tests.image.tag` | `busybox`, `1.37` | Image for the `helm test` pod |
