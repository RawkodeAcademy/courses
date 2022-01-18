# Teleport on Kubernetes

## Setup

- [ ] A Kubernetes cluster
- [ ] A domain name you want to use for the Teleport server

## Exercise 1. Find the Helm Charts

Spoiler alert: it's in `./examples/chart/` of `teleport/teleport`.

There are a few different charts available. Let's break them down.

### teleport-cluster

This chart sets up a single node Teleport cluster. It uses a persistent volume claim for storage. Great for getting started with Teleport.

### teleport

**Deprecated**

This chart sets up a single node Teleport cluster. It uses a persistent volume claim for storage. Great for getting started with Teleport.

### teleport-daemoneset

**Deprecated**

This chart allows you to connect the nodes from your Kubernetes cluster to a Teleport cluster.

### teleport-kubeagent

Use this chart to connect a Kubernetes cluster to your existing Teleport cluster. Can also facilitate running App an DB proxies.

### teleport-auto-trustedcluster

**Deprecated**

This chart deploys a Teleport cluster within your Kubernetes cluster, but also dials back to a root cluster to allow federated management.

### What should I Use?

I'd encourage you to use `teleport-cluster` for running a Teleport on Kubernetes and `teleport-daemonset` an `teleport-kubeagent` for connecting your cluster to an existing Teleport Cluster.

## Exercise 2. Install Teleport

**Warning:** These charts are not published to the Artifact Hub. Please note that there are some unofficial Charts published there and it's at your own discretion if you opt to use them.

To use these charts, add the Teleport Helm repository:

```shell
# Now you can deploy these charts using their name with a teleport/ prefix
helm repo add teleport https://charts.releases.teleport.dev
```

or clone the Teleport repository locally:

```shell
# Now you can deploy the charts using a local path of `./examples/chart/<chart name>`.
git clone https://github.com/gravitational/teleport
```

Let's deploy the `teleport-cluster` chart.

```shell
helm install teleport-cluster \
    --set acme=true \
    --set acmeEmail=david@rawkode.com \
    --set clusterName=teleport.rawkode.sh \
    --create-namespace \
    --namespace=teleport-cluster \
    teleport/teleport-cluster
```

### ACME Challenge

Whichever route you take, you'll be stuck waiting for the ACME certificate to be issued. We need to setup our DNS record to point to the cluster.

- [ ] Create a DNS record pointing to the cluster

### Omitting the LoadBalancer Service

LoadBalancer services can be quite expensive and you may wish to avoid going down that route. It's often preferred to use an Ingress resource to route traffic within your cluster, which means all (or some of) public facing traffic will be routed through a single LoadBalancer.

```shell
helm install teleport-cluster \
    --set acme=true \
    --set acmeEmail=david@rawkode.com \
    --set clusterName=teleport.rawkode.sh \
    --set service.type=ClusterIP \
    --create-namespace \
    --namespace=teleport-cluster \
    ./teleport/examples/chart/teleport-cluster/
```

You'll need to create some sort of Ingress resource to route the external traffic to your ClusterIP service. Here's an example using Emissary Ingress.

```yaml
apiVersion: getambassador.io/v3alpha1
kind: Mapping
metadata:
  name: teleport
spec:
  hostname: teleport.rawkode.sh
  prefix: /
  service: ??
```

- [ ] Complete ACME Challenge Above

## Exercise 3. Install DaemonSet

The installation above doesn't give us server access to our underlying nodes. For that, we need to go rogue. Unfortunately, the Teleport DaemonSet chart is deprecated and it also deployed its own Teleport cluster too. That doesn't mean we can't use parts of it to get what we need.

**Warning:**

I doubt this is encouraged by Teleport themselves, but it'll get you going. When you deploy this DaemonSet to your cluster, you have some extremely privileged pods that can access your nodes.

### Add a Static Join Token for Nodes

First, we need to modify the ConfigMap deployed by our teleport-cluster chart.

**Any upgrades to this chart will remove your changes.**

```yaml
auth_service:
  enabled: true
  tokens:
  # If using static tokens we recommend using tools like `pwgen -s 32`
  # to generate sufficiently random tokens of 32+ byte length
  - node:SOME_STRING
```

Next, you'll need to delete the pod so that Teleport is restarted with our change.

```shell
kubectl delete pod -l app=teleport-cluster
```

Finally, we can deploy a DaemonSet with a rather scary set of prvileges 😅

**Remember** Update the auth token to match the one you used above.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: teleport-ds-config
data:
  teleport.yaml: |
    auth_service:
      enabled: false
    proxy_service:
      enabled: false
    ssh_service:
      enabled: true
      labels:
        node-type: kubernetes-worker
    teleport:
      auth_servers:
      - teleport.rawkode.sh:443
      auth_token: RANDOM
      log:
        output: /var/log/teleport.log
        severity: DEBUG
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: teleport-ds
spec:
  selector:
    matchLabels:
      app: teleport-ds
  template:
    metadata:
      labels:
        app: teleport-ds
    spec:
      hostPID: true
      hostIPC: true
      hostNetwork: true
      containers:
        - name: teleport
          image: "quay.io/gravitational/teleport:8"
          securityContext:
            privileged: true
          resources: {}
          volumeMounts:
            - mountPath: /etc/teleport
              name: teleport-ds-config
              readOnly: true
      volumes:
        - name: teleport-ds-config
          configMap:
            name: teleport-ds-config
```

## Exercise 4. Install KubeAgent

With this chart, we're going to expose a Kubernetes cluster to an existing Teleport cluster.

You'll need to use one of the existing clusters, from above, or Teleport Cloud.

To generate a token for this service:

```shell
tctl tokens add --type kube --ttl=48h kube-1
```

Then deploy the Helm Chart with the relevant information.

```shell
helm install teleport-kube-agent \
  --create-namespace \
  --namespace teleport \
  --set roles=kube \
  --set proxyAddr=rawkode.teleport.sh:443 \
  --set authToken=? \
  --set kubeClusterName=civo-2 \
  teleport/teleport-kube-agent
```
