import * as cloudinit from "@pulumi/cloudinit";
import * as fs from "fs";

const scriptPart = (
  scriptName: string
): cloudinit.types.input.GetConfigPart => ({
  contentType: "text/x-shellscript",
  content: fs.readFileSync(`cloud-config/${scriptName}.sh`, "utf8"),
});

export const cloudConfig = cloudinit.getConfig({
  gzip: false,
  base64Encode: false,
  parts: [
    scriptPart("essentials"),
    scriptPart("teleport-install"),
    scriptPart("teleport-configure"),
    scriptPart("teleport-restart"),
  ],
});
