import * as linode from "@pulumi/linode";

const teleportServer = new linode.Instance("teleport-server", {
  label: "teleport-server",
  type: "g6-nanode-1",
  region: "eu-west",
  image: "linode/ubuntu20.04",
  rootPass: "rawkode-super-secret-password",
});

const teleportWorker1 = new linode.Instance("teleport-worker-1", {
  label: "teleport-worker-1",
  type: "g6-nanode-1",
  region: "eu-west",
  image: "linode/debian10",
  rootPass: "rawkode-super-secret-password",
});

const teleportWorker2 = new linode.Instance("teleport-worker-2", {
  label: "teleport-worker-2",
  type: "g6-nanode-1",
  region: "eu-west",
  image: "linode/arch",
  rootPass: "rawkode-super-secret-password",
});

const teleportWorker3 = new linode.Instance("teleport-worker-3", {
  label: "teleport-worker-3",
  type: "g6-nanode-1",
  region: "eu-west",
  image: "linode/fedora35",
  rootPass: "rawkode-super-secret-password",
});
