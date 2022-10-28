# Into Production

## Setup

- [ ] Uninitialised Teleport Cluster

## Exercise 1. Monitoring Teleport with Prometheus

Teleport can be monitored with Prometheus, or anything capable of scraping Prometheus endpoints, but it does need to be enabled first.

Teleport can be passed a `diag-addr` parameter that allows you to specify the interface and port that diagnostic information should be made available.

- [ ] Enable diagnostics
- [ ] Curl metrics endpoint

## Exercise 2. Did somebody say stateful? 😅

We've not really covered this much in the previous sessions ... but here's a truth bomb coming your way:

**Teleport is a very stateful application**

Teleport has 3 types of state that need handled in a production environment:

1. Cluster State
2. Audit Events
3. Session Recordings

### Part 1. Elastic Storage

The simplest solution to this problem is to use a cloud provider block storage device, such as EBS on AWS or GCD on Google Cloud.

Why? Because you can use a single configuration at the infrastructure layer to persist the state of the cluster.

Your missions?

- [ ] Use the Pulumi program in `./exercise-2` and add enough cloud-init to persist the cluster state.
