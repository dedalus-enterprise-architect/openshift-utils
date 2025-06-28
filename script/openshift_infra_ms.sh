#!/bin/bash

NAMESPACE="openshift-machine-api"
WORKER_MACHINESET=$(oc get machineset -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')

if [ -z "$WORKER_MACHINESET" ]; then
    echo "Error: No worker MachineSet found in namespace $NAMESPACE"
    exit 1
fi

CLUSTER_ID=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
INFRA_MACHINESET_NAME="${CLUSTER_ID}-infra"
OUTPUT_FILE="infra-machineset.yaml"
TEMP_FILE="worker.yaml"

oc get machineset "$WORKER_MACHINESET" -n $NAMESPACE -o yaml > "$TEMP_FILE"

yq e 'del(.status)' -i "$TEMP_FILE"

yq e ".metadata.name = \"$INFRA_MACHINESET_NAME\"" -i "$TEMP_FILE"
yq e ".metadata.namespace = \"$NAMESPACE\"" -i "$TEMP_FILE"
yq e ".metadata.labels.\"machine.openshift.io/cluster-api-cluster\" = \"$CLUSTER_ID\"" -i "$TEMP_FILE"
yq e ".metadata.labels.\"machine.openshift.io/cluster-api-machineset\" = \"$INFRA_MACHINESET_NAME\"" -i "$TEMP_FILE"

yq e ".spec.selector.matchLabels.\"machine.openshift.io/cluster-api-cluster\" = \"$CLUSTER_ID\"" -i "$TEMP_FILE"
yq e ".spec.selector.matchLabels.\"machine.openshift.io/cluster-api-machineset\" = \"$INFRA_MACHINESET_NAME\"" -i "$TEMP_FILE"

yq e ".spec.template.metadata.labels.\"machine.openshift.io/cluster-api-cluster\" = \"$CLUSTER_ID\"" -i "$TEMP_FILE"
yq e ".spec.template.metadata.labels.\"machine.openshift.io/cluster-api-machine-role\" = \"infra\"" -i "$TEMP_FILE"
yq e ".spec.template.metadata.labels.\"machine.openshift.io/cluster-api-machine-type\" = \"infra\"" -i "$TEMP_FILE"
yq e ".spec.template.metadata.labels.\"machine.openshift.io/cluster-api-machineset\" = \"$INFRA_MACHINESET_NAME\"" -i "$TEMP_FILE"

yq e ".spec.template.spec.metadata.labels.\"node-role.kubernetes.io/infra\" = \"\"" -i "$TEMP_FILE"

yq e ".spec.template.spec.taints = [{\"key\": \"node-role.kubernetes.io/infra\", \"value\": \"reserved\", \"effect\": \"NoSchedule\"}, {\"key\": \"node-role.kubernetes.io/infra\", \"value\": \"reserved\", \"effect\": \"NoExecute\"}]" -i "$TEMP_FILE"

mv "$TEMP_FILE" "$OUTPUT_FILE"

echo "Infra MachineSet manifest created: $OUTPUT_FILE"
