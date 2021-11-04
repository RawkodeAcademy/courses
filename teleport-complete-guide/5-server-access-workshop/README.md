# Server Access

## Setup

To work through this workshop, you'll need access to some servers. This directory contains some Pulumi code to spin up 4 Linodes, however you can use containers, VMs on any cloud, or even bare metal.

## Exercise 1. Create a Teleport Server

Using one of your "servers", install and create a Teleport server with a static authentication token for agents to join the cluster in the next exercise.

## Exercise 2. Join Nodes to Cluster

Using a static authentication token, join your other available nodes to the Teleport cluster.

## Exercise 3. Add Static Labels to Teleport Nodes

We plan to extend our Teleport cluster beyond our staging environment, to include a single cluster for QA. As such, we need to be able to address all our staging and QA nodes accordingly.

Add "environment" = "staging" labels to existing nodes.

## Exercise 4. Add Dynamic Labels to Teleport Nodes

Add two dynamic labels to all the nodes within our Teleport cluster:

1. `app=nginx` when `nginx` is running on the node updated every 15m
2. `users=<number of users>` when there are active sessions on the node, updated every 30s

## Exercise 5. Sprinkle eBPF Dust

Enable "enhanced" recording on one of your nodes and confirm it is working by writing a file with all the commands and arguments executed on the node.

**Bonus:** Run the following shell script and check the logs:

```console
#!/usr/bin/env sh
mkdir -p /tmp/teleport
echo "Hello, eBPF" > /tmp/teleport/eBPF.txt
curl -fsSL https://gist.githubusercontent.com/rawkode/1475ac2ca69a2d18d001cc0ed166c712/raw/fe71fb034814524d006856ce10710f7aac81c1f2/state.sls > /tmp/teleport/state.sls
ls /tmp/teleport
rm -rf /tmp/teleport
```

### Exercise 6. Managing Users

1. Create a new `admin` user called `l33t` that has root access to all nodes
2. Delete `l33t` user
3. Create a new `access` user called `pawn` with an invitation ttl of 48 hours, with standard user access to all nodes

## Exercise 7. SSH via UI

1. Execute `whoami` on another one of your nodes
2. Execute `who` on another one of your nodes
3. Execute `last` on another one of your nodes

## Exercise 8. Join an Active Session

1. Create a standard user session on one of your nodes
2. Execute `cat /etc/shadow`
3. Open the `/etc/passwd` file with `vim`
4. Join the open session with the `pawn` user and edit the file with the sessions side-by-side
5. Quit `vim` without saving ... though you shouldn't be able to save anyway 😅

## Exercise 9. Session Replay

1. Watch the recording of Exercise 8
2. Copy the hashed password from the `/etc/shadow` file for the `ubuntu` user

## Exercise 10. Audit Logs

Find the "join" event in the Teleport audit log

## Exercise 11. Configure `tsh` Locally

Get `tsh` working on your local machine to communicate and interact with our Teleport cluster.

## Exercise 12. Join an Active Session

1. Create a standard user session on one of your nodes
2. Join the open session with the `pawn` user using `tsh`
3. Execute `ps aux`

## Exercise 13. Create a File on All Staging Nodes

Execute "echo 'hi' > /tmp/hello" on all staging nodes with `tsh`

## Exercise 14. Output Parsing

IT needs a file that contains the IP and UUID of every node within the Teleport cluster.

## Exercise 15. Session Replay with CLI

1. Watch the recording of Exercise 8 with `tsh`
