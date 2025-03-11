# OpenShift utils

## Script Documentation

| Script Name | Description | Parameters | Example Usage |
|-------------|-------------|------------|---------------|
| `openshift_infra_ms.sh` | Creates an infrastructure MachineSet manifest for an OpenShift cluster. | None | `./openshift_infra_ms.sh` |
| `openshift_monitoring_core.sh` | Configures Prometheus and AlertManager with persistent storage in OpenShift. | `-s, --storage-class` (default: gp3-csi), `-z, --storage-size` (default: 25Gi), `-r, --retention` (default: 15d), `-i, --infra-nodes` (default: false) | `./openshift_monitoring_core.sh -s gp3-csi -z 50Gi -r 30d -i true` |
| `openshift_resources_report.sh` | Generates a CSV report of resource usage for deployments, deployment configs, stateful sets, and daemon sets in a specified namespace. | Namespace (first argument) | `./openshift_resources_report.sh my-namespace` |
