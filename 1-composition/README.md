# Composition

In this demonstration, we're going to install a Composition from a Package. This section assumes you have installed Crossplane and have AWS authentication configured.

## Installing the Configuration Package

Configuration Packages contain manifests

We'll install an EKS configuration from the Upbound Marketplace. Go to <https://marketplace.upbound.io/configurations/upbound/configuration-aws-eks/v0.10.0> and click on the `Install Manifest` button.

A sample configuration package is below:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: upbound-configuration-aws-eks
spec:
  package: xpkg.upbound.io/upbound/configuration-aws-eks:v0.10.0

```

Confirm the configuration packages have been installed:

```shell
kubectl get -f configuration.yaml 
NAME                            INSTALLED   HEALTHY   PACKAGE                                                 AGE
upbound-configuration-aws-eks   True        True      xpkg.upbound.io/upbound/configuration-aws-eks:v0.10.0   6s
```

This package contains XRDs and Compositions to create a VPC network and EKS cluster. The source code is at <https://github.com/upbound/configuration-aws-eks/tree/main/apis>.

## Create the Network Composite Resource (XR)

Create the network XR and wait for it to become healthy:

```shell
$ kubectl apply -f network-xr.yaml
xnetwork.aws.platform.upbound.io/configuration-aws-eks created
```

```shell
kubectl get -f network-xr.yaml 
NAME                    SYNCED   READY   COMPOSITION                         AGE
configuration-aws-eks   True     True    xnetworks.aws.platform.upbound.io   6h30m
```

We can trace the composite:

```shell
crossplane beta trace xnetwork.aws.platform.upbound.io/configuration-aws-eks
```

## Create the EKS Cluster

Create the EKS XR and wait for it to become healthy:

```shell
$ kubectl apply -f eks-xr.yaml 
xeks.aws.platform.upbound.io/configuration-aws-eks created
```

```shell
crossplane beta trace xeks.aws.platform.upbound.io/configuration-aws-eks
```

## Cleanup

Make sure to remove all resources:

````shell
kubectl delete -f eks-xr.yaml
kubectl delete -f network-xr.yaml
```
