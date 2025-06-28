#!/bin/bash

# Simple check for required binaries
for bin in oc jq; do
  if ! command -v "$bin" >/dev/null; then
    echo "Error: '$bin' is required but not found in PATH." >&2
    echo "Please install '$bin' and ensure it is available in your PATH environment variable." >&2
    exit 1
  fi
done

# Define the namespace from the first argument
NAMESPACE="$1"
CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="${NAMESPACE}_${CLUSTER_NAME}_${DATE}.csv"

# Write the CSV header
echo "Kind,Name,Replicas,Container,Type,CPU Request (mC),Memory Request (MiB),CPU Limit (mC),Memory Limit (MiB),Readiness Probe Time" > "$OUTPUT_FILE"

# Get the JSON output of all relevant resources
oc get deployment,deploymentconfig,statefulset,daemonset -n "$NAMESPACE" -o json | jq -r '
  def to_millicores:
    if type == "string" then
      if endswith("m") then .[:-1] else tostring | tonumber * 1000 | tostring end
    else
      "null"
    end;
  
  def to_mebibytes:
    if type == "string" then
      if endswith("Gi") then (.[:-2] | tonumber * 1024 | tostring)
      elif endswith("Mi") then .[:-2]
      elif endswith("Ki") then (.[:-2] | tonumber / 1024 | tostring)
      else (tonumber / (1024*1024) | tostring)
      end
    else
      "null"
    end;
  
  .items[] as $item |
  ($item.spec.template.spec.initContainers[]?, $item.spec.template.spec.containers[]?) as $container |
  [
    $item.kind,
    $item.metadata.name,
    ($item.spec.replicas // "null"),
    $container.name,
    (if ($item.spec.template.spec.initContainers | index($container)) then "initContainer" else "container" end),
    ($container.resources.requests.cpu | to_millicores // "null"),
    ($container.resources.requests.memory | to_mebibytes // "null"),
    ($container.resources.limits.cpu | to_millicores // "null"),
    ($container.resources.limits.memory | to_mebibytes // "null"),
    ($container.readinessProbe.initialDelaySeconds // "null")
  ] | @csv' >> "$OUTPUT_FILE"

echo "Output saved to $OUTPUT_FILE"

