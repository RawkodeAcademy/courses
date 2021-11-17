import * as pulumi from "@pulumi/pulumi";
import * as linode from "@pulumi/linode";
import * as random from "@pulumi/random";

const currentProfile = pulumi.output(linode.getProfile({ async: true }));

const randomRandomString = new random.RandomString("random", {
  length: 32,
  special: false,
});

export const serverPassword = randomRandomString.result;

const teleportServer = new linode.Instance(
  "teleport-server",
  {
    label: "teleport-server",
    type: "g6-nanode-1",
    privateIp: true,
    region: "eu-west",
    image: "linode/ubuntu20.04",
    rootPass: randomRandomString.result,
    authorizedUsers: [currentProfile.username],
  },
  {
    deleteBeforeReplace: true,
  }
);

const teleportWorker1 = new linode.Instance(
  "teleport-worker-1",
  {
    label: "teleport-worker-1",
    type: "g6-nanode-1",
    privateIp: true,
    region: "eu-west",
    image: "linode/ubuntu20.04",
    rootPass: randomRandomString.result,
    authorizedUsers: [currentProfile.username],
  },
  {
    deleteBeforeReplace: true,
  }
);
