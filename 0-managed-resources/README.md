# Managed Resources

A [Managed Resource](https://docs.crossplane.io/v1.15/concepts/managed-resources/) is a high-fidelity Kubernetes representation of a remote resource. In this example we'll create an AWS S3 bucket using Crossplane.

## Installing Crossplane

Install Crossplane via the [Getting Started](https://docs.crossplane.io/v1.15/getting-started/provider-aws/) guide.

## Installing the S3 Provider

Once Crossplane is installed, install the AWS Provider onto a Crossplane Cluster from the manifest at <https://marketplace.upbound.io/providers/upbound/provider-aws-s3/v1.1.1>.

The major Cloud providers (AWS, Azure, GCP) are broken up in to "family" providers in order to reduce CRDs installed on the cluster.

```shell
kubectl apply -f provider.yaml
```

Verify that your Provider was installed Correctly. You should see that the `upbound-provider-family-aws` provider was automatically installed. This provider supplies the common `ProviderConfig` CRD.

```shell
$ kubectl get provider.pkg
NAME                      INSTALLED   HEALTHY   PACKAGE                                          AGE
upbound-provider-aws-s3   True        True      xpkg.upbound.io/upbound/provider-aws-s3:v1.1.1   9m
upbound-provider-family-aws              True        True      xpkg.upbound.io/upbound/provider-family-aws:v1.1.01              10m
```

## Creating a Secret

In this example, we are going to create a Kubernetes secret that contains AWS credentials to allow Crossplane to provision AWS Resources.

The provider will look for `[default]` credentials in the secret with the following format. Save your credentials into the file `aws-credentials.txt`.

```ini
[default]
aws_access_key_id = ...
aws_secret_access_key = ...
```

Next create the secret. Note the secret `name`, `namespace`. In this example, the secret key will be `creds`.

```shell
kubectl create secret \
generic aws-secret \
-n crossplane-system \
--from-file=creds=./aws-credentials.txt

```

### Create the ProviderConfig

`ProviderConfigs` tell Crossplane Providers how to authenticate to remote APIs. There can be multiple ProviderConfigs on a Crossplane Cluster. The `default` ProviderConfig is used by default.

Your ProviderConfig should match the `name`, `namespace`, and `key` of the secret you created:

```yaml
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-secret
      key: creds
```

## Deploying the S3 Bucket

To create an S3 Bucket in AWS, we apply a manifest to our cluster:

```shell
$ kubectl apply -f bucket.yaml
bucket.s3.aws.upbound.io/bensheim-bucket created
```

You can examine the bucket and look at events using `describe`. Most Managed Resources expose the following status conditions:

- `SYNCED`: the Provider can communicate with the remote API
- `READY`: the Managed Resource is ready for use

```shell
$ kubectl get -f bucket.yaml
NAME                       READY   SYNCED   EXTERNAL-NAME              AGE
bensheim-bucket            True    True     bensheim-bucket            99s
```

```shell
kubectl describe -f bucket.yaml
```

## Cleanup

Delete the bucket:

```shell
$ kubectl delete -f bucket.yaml
bucket.s3.aws.upbound.io "bensheim-bucket" deleted
```
