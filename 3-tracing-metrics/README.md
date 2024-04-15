# Observing Crossplane

## crossplane top

The `crossplane top` command can be used to monitor Crossplane-related

Ensure the metics server is enabled. Below is a Helm example. For `kind` installation, the `--kubelet-insecure-tls` option must be set.

```shell
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm upgrade --install --set args={--kubelet-insecure-tls} metrics-server metrics-server/metrics-server --namespace kube-system
```

It will take a few seconds for metrics to be available. Next, run `crossplane beta top`:

```shell
$ crossplane beta top
TYPE         NAMESPACE        NAME                                                              CPU(cores)   MEMORY
crossplane   crossplane-system   crossplane-6d5575b698-jmx9l                                       74m          131Mi
crossplane   crossplane-system   crossplane-rbac-manager-dcfdc8954-qkl4d                           5m           19Mi
function     crossplane-system   crossplane-contrib-function-patch-and-transform-fd0ee2635bxkcsz   0m           13Mi
function     crossplane-system   function-go-templating-eff9a0400879-79b5d5bd6d-nb8b8              0m           6Mi
provider     crossplane-system   crossplane-contrib-provider-helm-b4cc4c2c8db3-6d787f9686-hr5x8    1m           21Mi
provider     crossplane-system   crossplane-contrib-provider-kubernetes-83c72134f895-589646c5g5n   6m           24Mi
provider     crossplane-system   upbound-provider-aws-ec2-8c70ac53bb1a-69f7c86c4d-7kqfw            12m          203Mi
provider     crossplane-system   upbound-provider-aws-eks-23042d28ed58-6f9598f984-mhsbc            18m          132Mi
provider     crossplane-system   upbound-provider-aws-iam-28cb496c46b8-6cd48c574d-s6n88            4m           162Mi
provider     crossplane-system   upbound-provider-aws-kms-5198510e1510-5c696f8c8b-2ssxl            2m           102Mi
provider     crossplane-system   upbound-provider-aws-lambda-3c4fe915b54a-6866dfdc7c-dqb6f         17m          118Mi
provider     crossplane-system   upbound-provider-aws-s3-6ca829a5198b-5586fdcd94-vv5z9             6m           110Mi
provider     crossplane-system   upbound-provider-aws-ssm-5bd46deb407c-6f99b9649-hx94k             4m           132Mi
provider     crossplane-system   upbound-provider-family-aws-3756efeec089-78df6446f6-5gj6n         2m           110Mi
```

## Metrics

The core Crossplane engine, Providers, and Functions all emit standard Prometheus metrics like CPU and Memory. However, Crossplane can also emit Managed Resource and Composite using the [x-metrics](https://github.com/crossplane-contrib/x-metrics) project.

Based on the experience with x-metrics, high level metrics are being added to the providers. See crossplane issue [#4620](https://github.com/crossplane/crossplane/issues/4620).

## Installing x-metrics

Install x-metrics into your cluster:

```shell
helm repo add x-metrics https://crossplane-contrib.github.io/x-metrics
helm install x-metrics x-metrics/x-metrics --namespace x-metrics --create-namespace --wait
```

Now that `x-metrics` is installed, let's use kubernetes port-forwarding to access the port:

```shell
kubectl --namespace x-metrics port-forward svc/x-metrics 8080:8080
```

Metrics will be available at  <http://127.0.0.1:8080/x-metrics>.

## Enabling Metrics

Create a monitor for provider-kubernetes [Objects]()

```shell
kubectl apply -f provider-kubernetes.yaml
```

Metrics also support wildcards and matching API groups. For example, (upbound-aws-all.yaml)

```yaml
apiVersion: metrics.crossplane.io/v1
kind: ClusterMetric
metadata:
  name: aws-upbound-provider-all
spec:
  matchName: ".aws.upbound.io"
```

```shell
kubectl apply -f upbound-aws-all.yaml
clustermetric.metrics.crossplane.io/aws-upbound-provider-all created
```

Now if we create a resource like the bucket, we should have metrics available at the prometheus endpoint:

```shell
$kubectl apply -f ../0-managed-resources/bucket.yaml
bucket.s3.aws.upbound.io/borrelli-incontro-devops created
```

Connect to the metrics endpoint and search in your browser for `s3_aws_upbound_io_Bucket_` (note the trailing underscore to filter out other S3 resources). You should have a list of the metrics collected at the Managed Resource level:

```
# TYPE s3_aws_upbound_io_Bucket_v1beta1 gauge
# HELP s3_aws_upbound_io_Bucket_v1beta1 A metrics series for each object
s3_aws_upbound_io_Bucket_v1beta1{name="borrelli-incontro-devops"} 1
# TYPE s3_aws_upbound_io_Bucket_v1beta1_created gauge
# HELP s3_aws_upbound_io_Bucket_v1beta1_created Unix creation timestamp
s3_aws_upbound_io_Bucket_v1beta1_created{name="borrelli-incontro-devops"} 1.710254658e+09
# TYPE s3_aws_upbound_io_Bucket_v1beta1_labels gauge
# HELP s3_aws_upbound_io_Bucket_v1beta1_labels Labels from the kubernetes object
s3_aws_upbound_io_Bucket_v1beta1_labels{name="borrelli-incontro-devops",label_owner="borrelli"} 1
# TYPE s3_aws_upbound_io_Bucket_v1beta1_info gauge
# HELP s3_aws_upbound_io_Bucket_v1beta1_info A metrics series exposing parameters as labels
s3_aws_upbound_io_Bucket_v1beta1_info{name="borrelli-incontro-devops"} 1
# TYPE s3_aws_upbound_io_Bucket_v1beta1_ready gauge
# HELP s3_aws_upbound_io_Bucket_v1beta1_ready A metrics series mapping the Ready status condition to a value (True=1,False=0,other=-1)
s3_aws_upbound_io_Bucket_v1beta1_ready{name="borrelli-incontro-devops"} 1
# TYPE s3_aws_upbound_io_Bucket_v1beta1_ready_time gauge
# HELP s3_aws_upbound_io_Bucket_v1beta1_ready_time Unix timestamp of last ready change
s3_aws_upbound_io_Bucket_v1beta1_ready_time{name="borrelli-incontro-devops"} 1.710254691e+09
# TYPE s3_aws_upbound_io_Bucket_v1beta1_synced gauge
# HELP s3_aws_upbound_io_Bucket_v1beta1_synced A metrics series mapping the Synced status condition to a value (True=1,False=0,other=-1)
s3_aws_upbound_io_Bucket_v1beta1_synced{name="borrelli-incontro-devops"} 1
# TYPE s3_aws_upbound_io_Bucket_v1beta1_synced_time gauge
# HELP s3_aws_upbound_io_Bucket_v1beta1_synced_time Unix timestamp of last synced change
s3_aws_upbound_io_Bucket_v1beta1_synced_time{name="borrelli-incontro-devops"} 1.710254661e+09
# TYPE s3_aws_upbound_io_Bucket_v1beta1_resource_count gauge
# HELP s3_aws_upbound_io_Bucket_v1beta1_resource_count A metrics series objects to count objects of s3_aws_upbound_io_Bucket_v1beta1
s3_aws_upbound_io_Bucket_v1beta1_resource_count 1
```
