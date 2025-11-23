# Changelog

All notable changes to this project will be documented in this file.

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
