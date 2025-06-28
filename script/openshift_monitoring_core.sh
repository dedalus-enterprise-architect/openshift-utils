#!/bin/bash

# Script to configure Prometheus and AlertManager with persistent storage using yq

# Default values for storage configuration
STORAGE_CLASS="gp3-csi"
STORAGE_SIZE="25Gi"
RETENTION_TIME="15d"
USE_INFRA_NODES="false"

# Function to display help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Configure Prometheus and AlertManager with persistent storage in OpenShift"
    echo ""
    echo "Options:"
    echo "  -s, --storage-class    Storage class to use (default: gp3-csi)"
    echo "  -z, --storage-size     Size of persistent volume (default: 25Gi)"
    echo "  -r, --retention        Data retention period (default: 15d)"
    echo "  -i, --infra-nodes      Deploy on infrastructure nodes (default: false)"
    echo "  -h, --help             Display this help message"
    echo ""
    echo "Example:"
    echo "  $0 -s gp3-csi -z 50Gi -r 30d -i true"
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -s|--storage-class)
            STORAGE_CLASS="$2"
            shift 2
            ;;
        -z|--storage-size)
            STORAGE_SIZE="$2"
            shift 2
            ;;
        -r|--retention)
            RETENTION_TIME="$2"
            shift 2
            ;;
        -i|--infra-nodes)
            USE_INFRA_NODES="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
 done

# Set output file name
OUTPUT_FILE="monitoring-config.yaml"

# Create base ConfigMap structure
cat > "$OUTPUT_FILE" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    alertmanagerMain:
EOF

# Add infrastructure node configuration if enabled
if [ "$USE_INFRA_NODES" = "true" ]; then
    cat >> "$OUTPUT_FILE" << EOF
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        value: reserved
        effect: NoSchedule
      - key: node-role.kubernetes.io/infra
        value: reserved
        effect: NoExecute
EOF
fi

# Add AlertManager configuration
cat >> "$OUTPUT_FILE" << EOF
      volumeClaimTemplate:
        spec:
          storageClassName: ${STORAGE_CLASS}
          volumeMode: Filesystem
          resources:
            requests:
              storage: 5Gi
    prometheusK8s:
EOF

# Add infrastructure node configuration for Prometheus if enabled
if [ "$USE_INFRA_NODES" = "true" ]; then
    cat >> "$OUTPUT_FILE" << EOF
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        value: reserved
        effect: NoSchedule
      - key: node-role.kubernetes.io/infra
        value: reserved
        effect: NoExecute
EOF
fi

# Add Prometheus configuration
cat >> "$OUTPUT_FILE" << EOF
      enforcedBodySizeLimit: automatic
      retention: ${RETENTION_TIME}
      volumeClaimTemplate:
        spec:
          storageClassName: ${STORAGE_CLASS}
          volumeMode: Filesystem
          resources:
            requests:
              storage: ${STORAGE_SIZE}
EOF

# Add other components
for component in "prometheusOperator" "prometheusOperatorAdmissionWebhook" "k8sPrometheusAdapter" "kubeStateMetrics" "telemeterClient" "openshiftStateMetrics" "thanosQuerier" "monitoringPlugin"; do
    cat >> "$OUTPUT_FILE" << EOF
    ${component}:
EOF

    # Add infrastructure node configuration for each component if enabled
    if [ "$USE_INFRA_NODES" = "true" ]; then
        cat >> "$OUTPUT_FILE" << EOF
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        value: reserved
        effect: NoSchedule
      - key: node-role.kubernetes.io/infra
        value: reserved
        effect: NoExecute
EOF
    fi
done

echo "Monitoring configuration manifest has been generated: $OUTPUT_FILE"
echo "To apply the configuration, run:"
echo "oc -n openshift-monitoring apply -f $OUTPUT_FILE"
echo ""
echo "Configuration parameters:"
echo "Storage Class: ${STORAGE_CLASS}"
echo "Storage Size: ${STORAGE_SIZE}"
echo "Retention Time: ${RETENTION_TIME}"
echo "Infrastructure Nodes: ${USE_INFRA_NODES}"