# Role Based Access Control (RBAC) - Deep Dive

## Setup

- [ ] Uninitialised Teleport Cluster

## Exercise 1. Introduction to the Base Roles

Teleport ships with 3 roles that can be used right out of the box.

## Editor

Allows editing of cluster configuration settings.

## Auditor

Allows reading cluster events, audit logs, and playing back session records.

## Access

Allows access to cluster resources.

Let's create our first user with access to each of these roles.

```shell
tctl users add rawkode --roles=editor,auditor,access
```

## Exercise 2. Introduction to Traits

Before we talk about traits, do me a favour ... 

- [ ] Using Teleport, ssh into your control plane node and run `whoami`

**Warning:** You can't actually complete this task, yet 🤣

Why? Well, the `access` role that allows connecting to a Teleport node uses a trait to stub out the users that anyone with the role can connect as.

In previous workshops, when creating a user we always asked you to include `--logins=root`.  This explicitly adds the root login to our list of logins we can use.

The `access` role trait looks like this:

```yaml
# Scroll to the "Reference" at the bottom to see the entire role.
logins:
  - '{{internal.logins}}'
```

Teleport uses interpolation, signified by handlebar syntax, `{{ }}`, and `internal.logins` interpolates to the list of logins provided during `tctl users add`, or the users name by default.

Now, while we can use the Teleport UI to edit roles and users (limited), we can't to modify a users traits. So in-order to give ourselves the `root` login on our nodes, we need to use the CLI to pull down the YAML and make our change.

```shell
tctl get users/david@rawkode.com > rawkode.yaml
# edit edit edit
tctl create -f rawkode.yaml
```

- [ ] Modify the `logins` trait to include `root`
- [ ] Using Teleport, ssh into your control plane node and run `whoami`

Well done!

## Exercise 3. Edit Roles

- [ ] Remove the auditor role from your user using `tctl`

While we can use `get users/username` to pull down the YAML, there is a slightly convenient helper to set the roles someone has access to.

```shell
tctl users update alice --set-roles=editor,access
```

## Exercise 4. Limiting Access with Node Labels

- [ ] Limit access to your control plane node by using a node label and editing the role to include the node label

This should be pretty straight forward. If you need help, use the [docs](https://goteleport.com/docs/setup/admin/labels/#labeling-nodes-and-applications).


## Exercise 5. Approval Process for Roles

This is one of my favourite features of Teleport: allowing users to request elevated access.

- [ ] Create a new user with an `sre` role
- [ ] Create a new user with an `production` role
- [ ] Configure these roles so that production access needs approval from an `sre` user
- [ ] Request elevated access to the `production` role from the `sre` user

The YAML is below, but if you want to try without - some docs on this are [here](https://goteleport.com/docs/access-controls/guides/dual-authz/).

<details><summary>Show me the YAML!</summary>
<p>

```yaml
kind: role
version: v4
metadata:
  name: sre
spec:
  allow:
    request:
      roles: ['production']
      thresholds:
        - approve: 2
          deny: 1
    review_requests:
      roles: ['production']
---
kind: role
version: v4
metadata:
  name: production
spec:
  allow:
    logins: ['root']
    node_labels:
      'env': 'production'
```

</p>
</details>

## Exercise 6. Locking Down Production

Following on from the previous exercise, let's now enforce session MFA on the production environment.

- [ ] Update the `production` role to require session MFA
- [ ] Assume the `production` role using the CLI (`tsh login --request-id`)
- [ ] SSH to a node in the production environment

<details><summary>Show me the YAML!</summary>
<p>

```yaml
kind: role
version: v4
metadata:
  name: production
spec:
  # We only need to add these two lines
  options:
    require_session_mfa: true
  allow:
    logins: ['root']
    node_labels:
      'env': 'production'
```

</p>
</details>

## Reference

### Editor Role YAML

```yaml
kind: role
metadata:
  description: Edit cluster configuration
  name: editor
spec:
  allow:
    rules:
    - resources:
      - user
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - role
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - oidc
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - saml
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - github
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - cluster_audit_config
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - cluster_auth_preference
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - auth_connector
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - cluster_name
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - cluster_networking_config
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - session_recording_config
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - trusted_cluster
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - remote_cluster
      verbs:
      - list
      - create
      - read
      - update
      - delete
    - resources:
      - token
      verbs:
      - list
      - create
      - read
      - update
      - delete
  deny: {}
  options:
    cert_format: standard
    enhanced_recording:
    - command
    - network
    forward_agent: true
    max_session_ttl: 30h0m0s
    port_forwarding: true
version: v4
```

### Auditor Role YAML

```yaml
kind: role
metadata:
  description: Review cluster events and replay sessions
  name: auditor
spec:
  allow:
    logins:
    - no-login-36c08a36-2f5b-4e69-af09-ef6d5f6e3c59
    rules:
    - resources:
      - session
      verbs:
      - list
      - read
    - resources:
      - event
      verbs:
      - list
      - read
  deny: {}
  options:
    cert_format: standard
    enhanced_recording:
    - command
    - network
    forward_agent: false
    max_session_ttl: 30h0m0s
    port_forwarding: true
version: v4
```

### Access Role YAML

```yaml
kind: role
metadata:
  description: Access cluster resources
  name: access
spec:
  allow:
    app_labels:
      '*': '*'
    db_labels:
      '*': '*'
    db_names:
    - '{{internal.db_names}}'
    db_users:
    - '{{internal.db_users}}'
    impersonate:
      roles:
      - Db
      users:
      - Db
    kubernetes_groups:
    - '{{internal.kubernetes_groups}}'
    kubernetes_labels:
      '*': '*'
    kubernetes_users:
    - '{{internal.kubernetes_users}}'
    logins:
    - '{{internal.logins}}'
    node_labels:
      '*': '*'
    rules:
    - resources:
      - event
      verbs:
      - list
      - read
    windows_desktop_labels:
      '*': '*'
    windows_desktop_logins:
    - '{{internal.windows_logins}}'
  deny: {}
  options:
    cert_format: standard
    enhanced_recording:
    - command
    - network
    forward_agent: true
    max_session_ttl: 30h0m0s
    port_forwarding: true
version: v4
```
