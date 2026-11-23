# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - Unreleased

A rewrite for Memos 26.11. Several values are renamed and the old names are rejected; see
[Upgrading from chart 0.2](charts/memos/README.md#upgrading-from-chart-02).

### Changed
- **BREAKING**: The chart moved to `charts/memos/` and is published to `oci://ghcr.io/usememos/charts/memos`.
- **BREAKING**: `image.repo` and `image.imageName` became `image.repository`; `image.tag` defaults to the chart `appVersion` instead of `latest`.
- **BREAKING**: `persistence.existPersistClaim` became `persistence.existingClaim`, `persistence.accessMode` became the list `persistence.accessModes`, `persistence.storageClass` defaults to the cluster default instead of `local`, and persistence is on by default.
- **BREAKING**: The pod runs as UID and GID 10001, the user of the current image, instead of 1000.
- **BREAKING**: Minimum Kubernetes version is 1.25.
- Memos application version from 0.25.2 to 26.11.2.
- Probes use `/healthz`, with a startup probe that leaves room for database migrations.
- The root filesystem is read-only, the seccomp profile is `RuntimeDefault`, and no service account token is mounted.
- The container always listens on 5230; `service.port` now changes only the Service.
- The Deployment uses `Recreate` for SQLite or a data volume, so an upgrade never waits on a volume the old pod still holds.
- The chart-managed volume claim is kept on uninstall unless `persistence.retain` is `false`.
- Default resources are requests only.

### Added
- MySQL and PostgreSQL through `database.driver` with `database.dsn` or `database.existingSecret`.
- Declarative configuration through `config.files`, `config.existingConfigMap`, and `config.existingSecret`, mounted at `/etc/memos/config`.
- `instanceUrl`, `extraEnv`, `extraEnvFrom`, `extraVolumes`, and `extraVolumeMounts`.
- Gateway API `HTTPRoute` through `httpRoute`.
- `values.schema.json`, which rejects unknown and misspelled values.
- `podLabels`, `service.annotations`, `service.nodePort`, `strategy`, `priorityClassName`, and `topologySpreadConstraints`.
- CI that lints and renders with Helm 3 and Helm 4, validates against Kubernetes schemas, and installs the chart on kind with SQLite, declarative configuration, and PostgreSQL.
- A release workflow that publishes on a version tag.

### Removed
- **BREAKING**: `autoscaling` and the HorizontalPodAutoscaler. Set `replicaCount`; SQLite supports one replica.
- The `Makefile` and the manual GitHub Pages publishing workflow.

## [0.2.1] - 2025-12-07

### Fixed
- Eliminate tabs in Chart.yaml to fix yaml errors

## [0.2.0] - 2025-11-23

### Changed
- **BREAKING**: Updated minimum Kubernetes version requirement to 1.19+
- Updated memos application version from 0.14.3 to 0.25.2 (11 versions ahead)
- Upgraded HPA API from `autoscaling/v2beta1` to `autoscaling/v2` for modern Kubernetes compatibility
- Simplified Ingress to use only `networking.k8s.io/v1` API (removed deprecated v1beta1 and extensions/v1beta1)
- Updated HPA metrics structure to match v2 API specifications

### Added
- Security best practices enabled by default:
  - Pod runs as non-root user (UID 1000)
  - All capabilities dropped
  - Privilege escalation disabled
- Default resource limits and requests configured
- Enhanced README with requirements, security, and resource configuration sections
- CHANGELOG.md for tracking version history

### Removed
- Support for Kubernetes < 1.19 (EOL versions)
- Deprecated API version compatibility code

## [0.1.0] - 2023-09-10

### Added
- Initial release of Memos Helm chart
- Support for memos version 0.14.3
- Basic deployment, service, and ingress configurations
- PVC support for data persistence
- HPA support for autoscaling
