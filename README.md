# Memos Helm chart

The Helm chart for running [Memos](https://github.com/usememos/memos) on Kubernetes.

```bash
git clone https://github.com/usememos/helm.git
```

```bash
helm install memos helm/charts/memos --namespace memos --create-namespace
```

The [chart README](charts/memos/README.md) covers databases, declarative configuration, ingress, upgrades, and every value.

## Repository layout

| Path | Holds |
| --- | --- |
| `charts/memos/` | The chart: templates, `values.yaml`, and `values.schema.json` |
| `charts/memos/ci/` | Values files that CI installs on a kind cluster; `ci/render/` is rendered and validated only |
| `scripts/validate.sh` | Lint, render, and schema validation, the same checks CI runs |
| `.github/workflows/ci.yml` | The checks that run on pull requests and on `main` |

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

## Versions

The chart is installed from this repository, and `main` is the current version. A change to the chart bumps `version` in
`charts/memos/Chart.yaml`, following SemVer, and adds an entry to `CHANGELOG.md`. For a new Memos release, set `appVersion` too.
