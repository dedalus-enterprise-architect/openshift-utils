# Kube-Green OpenShift Integration

This custom patch extends kube-green's functionality to handle OpenShift-specific DeploymentConfig resources only. It allows consistent sleep/wake behavior for OpenShift-specific workloads without needing to migrate DeploymentConfigs to Deployments. Regular Kubernetes Deployments will continue to be handled by kube-green's native functionality.

## SleepInfo Configuration

The `sleep-info.yaml` file contains the base SleepInfo resource definition, which controls when and how resources are scaled down and back up. This configuration specifically extends kube-green to support OpenShift DeploymentConfig resources only.

The original template-based approach using `$(VAR)` variables has been replaced with Kustomize's native configuration management for better maintainability and easier customization.

### Configuration

The SleepInfo resource can be configured with the following parameters:

| Parameter | Description | Example |
|----------|-------------|---------|
| Name prefix | Prefix added to the SleepInfo resource name. This will transform a SleepInfo named "sleep-schedule" to "app-sleep-schedule" if namePrefix is set to "app-" | `app-` |
| Namespace | Target namespace | `my-application` |
| Weekdays | Days when sleep/wake schedule applies (1=Monday, 7=Sunday) | `1-5` |
| SleepAt | Time to scale down resources | `18:00` |
| WakeUpAt | Time to scale back up resources | `08:00` |
| TimeZone | Timezone for sleep/wake schedule | `Europe/Rome` |

These parameters are now configured through Kustomize overlays or patches rather than variable substitution.

### Supported Resources

This patch is specifically designed to add support for:
- OpenShift DeploymentConfig resources (not natively supported by kube-green)

## Usage

You can apply this manifest in two ways:

### Using Kustomize

1. Install kube-green in your OpenShift cluster
2. Modify the values in the `kustomization.yaml` file to match your requirements:
   - Update `namePrefix` to set a prefix for the resource name (e.g., "app-" will create "app-sleep-schedule")
   - Update `namespace` to set the target namespace
   - Modify the patch values for weekdays, sleepAt, wakeUpAt, and timeZone
3. Apply the configuration:
   
   ```bash
   oc apply -k .
   ```

### Example Configuration

Here's an example of how to customize the `kustomization.yaml` file for different environments:

```yaml
# For development environment
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - sleep-info.yaml

# Custom settings
namePrefix: dev-
namespace: dev-namespace

# Configuration
patchesJson6902:
- target:
    group: kube-green.com
    version: v1alpha1
    kind: SleepInfo
    name: sleep-schedule
  patch: |
    - op: replace
      path: /spec/weekdays
      value: "1-5"
    - op: replace
      path: /spec/sleepAt
      value: "19:00"
    - op: replace
      path: /spec/wakeUpAt
      value: "08:00"
    - op: replace
      path: /spec/timeZone
      value: "Europe/Rome"
```

After modifying the configuration, apply it and verify:

```bash
# Apply the configuration
oc apply -k .

# Verify the SleepInfo resource
oc get sleepinfo -n dev-namespace
```

## Monitoring

You can check the status of your SleepInfo resource and its schedules:

```bash
oc describe sleepinfo dev-sleep-schedule -n dev-namespace
```

## Troubleshooting

If resources aren't scaling as expected:

1. Ensure the kube-green operator is running
2. Verify the timezone and times are correctly specified
3. Check operator logs for any errors:

   ```bash
   oc logs -f deployment/kube-green-controller-manager -n kube-green-system
   ```


