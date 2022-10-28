import * as google from "@pulumi/google-native";
import { cloudConfig } from "./cloud-config";

const computeNetwork = new google.compute.v1.Network("network", {
  autoCreateSubnetworks: true,
});

const computeFirewall = new google.compute.v1.Firewall("firewall", {
  network: computeNetwork.selfLink,
  allowed: [
    {
      ipProtocol: "tcp",
      ports: ["22", "80", "443"],
    },
  ],
});

const computeDisk = new google.compute.v1.Disk("teleport", {
  name: "teleport",
  sizeGb: "10",
});

const computeInstance = new google.compute.v1.Instance(
  "instance",
  {
    machineType: "f1-micro",
    metadata: {
      items: [
        {
          key: "user-data",
          value: cloudConfig.then((c) => c.rendered),
        },
      ],
    },
    disks: [
      {
        boot: true,
        initializeParams: {
          sourceImage:
            "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2110-impish-v20220203",
        },
      },
      {
        deviceName: "teleport",
        source: computeDisk.selfLink,
      },
    ],
    networkInterfaces: [
      {
        network: computeNetwork.id,
        accessConfigs: [{}], // must be empty to request an ephemeral IP
      },
    ],
    serviceAccounts: [
      {
        scopes: ["https://www.googleapis.com/auth/cloud-platform"],
      },
    ],
  },
  { dependsOn: [computeFirewall] }
);

export const instanceName = computeInstance.name;
export const instanceIP =
  computeInstance.networkInterfaces[0].accessConfigs[0].natIP;
