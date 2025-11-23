## Makefile for packaging and publishing the memos Helm chart
# Usage:
#  make package      # create a .tgz chart package
#  make oci-save     # save chart as OCI artifact locally
#  make oci-push     # push chart to GHCR (requires CR_PAT and USER env vars)

VERSION ?= $(shell grep '^version:' Chart.yaml | head -1 | awk '{print $$2}')
CHART_NAME := memos
OCI_REPO ?= ghcr.io/usememos/$(CHART_NAME)

.PHONY: package oci-save oci-push

package:
	helm package .

oci-save:
	helm chart save . $(OCI_REPO):$(VERSION)

oci-push:
	# Requires environment variables: USER and CR_PAT (or use your username and a PAT)
	@if [ -z "$(CR_PAT)" ]; then echo "CR_PAT environment variable is required to push to GHCR"; exit 1; fi
	helm registry login ghcr.io -u $(USER) -p $(CR_PAT)
	helm chart push $(OCI_REPO):$(VERSION)
