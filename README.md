# Memos Helm chart

The Helm chart for running [Memos](https://github.com/usememos/memos) on Kubernetes.

```bash
helm install memos oci://ghcr.io/usememos/charts/memos --namespace memos --create-namespace
```

The [chart README](charts/memos/README.md) covers databases, declarative configuration, ingress, upgrades, and every value.

## Repository layout

| Path | Holds |
| --- | --- |
| `charts/memos/` | The chart: templates, `values.yaml`, and `values.schema.json` |
| `charts/memos/ci/` | Values files that CI installs on a kind cluster; `ci/render/` is rendered and validated only |
| `scripts/validate.sh` | Lint, render, and schema validation, the same checks CI runs |
| `.github/workflows/` | `ci.yml` for pull requests, `release.yml` for publishing |

## Working on the chart

With [Helm](https://helm.sh) and [kubeconform](https://github.com/yannh/kubeconform) installed:

```bash
scripts/validate.sh
```

To try a change on a cluster:

```bash
helm upgrade --install memos charts/memos --namespace memos --create-namespace --wait
```

```bash
helm test memos --namespace memos
```

When a change adds or renames a value, update `values.yaml`, `values.schema.json`, and the values table in the chart README together.

## Releasing

1. Set `version` in `charts/memos/Chart.yaml`, following SemVer. For a new Memos release, set `appVersion` too.
2. Add the version to `CHANGELOG.md`.
3. Push a tag equal to the chart version, such as `1.0.0`.

The release workflow publishes the chart to `oci://ghcr.io/usememos/charts/memos` and attaches the package to a GitHub release.
