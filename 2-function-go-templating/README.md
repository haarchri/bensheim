# IAM Self Trust Role

This is an example Composition that shows how to create an explicit trust relationship for an IAM Role using [function-go-templating](https://github.com/crossplane-contrib/function-go-templating).

The composition first creates the IAM Role, and then uses the newly created Role ARN to populate the `principal` field. This shows how functions can use the `observed` state of a resource.

See <https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/> for more details.

## Example

The composition supports adding `additionalPrincipals`, `service`, `action`, that map to the same fields of an IAM policy.

```yaml
apiVersion: example.crossplane.io/v1alpha1
kind: XIAMSelfTrustRole
metadata:
  name: self-trust-test
spec:
  parameters:
    providerConfigName: default
    additionalPrincipals:
    - "arn:aws:iam::609897127049:user/bensheim"
    action:
    - "sts:AssumeRole"
    service:
    - "eks.amazonaws.com"
    - "ec2.amazonaws.com"
```

## Installation

Install functions:

```shell
kubectl apply -f functions.yaml
```

Ensure that the functions are healthy:

```shell
$ kubectl get -f functions.yaml
NAME                     INSTALLED   HEALTHY   PACKAGE
                     AGE
function-go-templating   True        True      xpkg.upbound.io/crossplane-contrib/function-go
-templating:v0.4.1   22h
function-auto-ready      True        True      xpkg.upbound.io/crossplane-contrib/function-au
to-ready:v0.2.1      57s

```

Install the IAM provider, and configure the `providerConfig` to your Organization standards.

```shell
kubectl apply -f provider.yaml
```

## Local Rendering

Use `crossplane beta render`. Note that we use the `-o` flag with an example observed manifest to simulate an actual Managed Resource:

```shell
crossplane beta render example/role.yaml apis/composition.yaml functions.yaml -o role-observed.yaml
```

## Creating the Role

Apply the XRD and Composition to the Cluster:

```shell
kubectl apply -f apis
composition.apiextensions.crossplane.io/xiamselftrustrole.example.crossplane.io created
compositeresourcedefinition.apiextensions.crossplane.io/xiamselftrustroles.example.crossplane.io created
```

Update/Remove the IAM role in [example/role.yaml](example/role.yaml) and apply the file.

```shell
$ kubectl apply -f example/role.yaml
xiamselftrustrole.example.crossplane.io/self-trust-test created
```

Trace the resulting resource, waiting for all resources to be `READY`:

```shell
crossplane beta trace xiamselftrustrole.example.crossplane.io/self-trust-test
NAME                                SYNCED   READY   STATUS
XIAMSelfTrustRole/self-trust-test   True     True    Available
└─ Role/self-trust-test-pjn24       True     True    Available
```

The arn should be populated to the status of the XR:

```shell
kubectl get XIAMSelfTrustRole/self-trust-test -o yaml | yq .status.arn
arn:aws:iam::609897127049:role/self-trust-test-pjn24
```

Now examine the Role to see that it added itself under `assumeRolePolicy`:

```shell
$ kubectl get role.iam self-trust-test-pjn24 -o yaml | yq .spec.forProvider.assumeRolePolicy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {

        "AWS": ["arn:aws:iam::609897127049:role/self-trust-test-pjn24","arn:aws:iam::609897127049:user/bensheim"],
        "Service": ["eks.amazonaws.com","ec2.amazonaws.com"]
      },
      "Action": ["sts:AssumeRole"]
    }
  ]
}
```
