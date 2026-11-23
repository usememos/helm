#!/usr/bin/env bash
# Lint the chart, render it with every values file under charts/memos/ci, and
# validate the result against the Kubernetes and Gateway API schemas.
# Needs helm and kubeconform on PATH.
set -euo pipefail

cd "$(dirname "$0")/.."

chart=charts/memos
kube_version=${KUBE_VERSION:-1.31.0}

helm lint --strict "$chart"

for values in "$chart/values.yaml" "$chart"/ci/*-values.yaml "$chart"/ci/render/*-values.yaml; do
  echo "==> $values"
  helm template memos "$chart" --namespace memos --kube-version "$kube_version" --values "$values" |
    kubeconform -strict -summary -kubernetes-version "$kube_version" \
      -schema-location default \
      -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
done
