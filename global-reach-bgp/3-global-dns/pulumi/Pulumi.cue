package pulumi

variables: {
	projectId: "f4db0408-fa3d-44b4-9547-7a1f15c6d132"
}

resources: {
	// Requires Special Handling
	// project: {
	//  type: "equinix-metal:Project"
	//  properties: {
	//   name: "Global DNS"
	//   bgpConfig: {
	//    asn: 65000
	//    // Approval for this will take 1-2 days.
	//    // That's why we're not using the project for the device
	//    deploymentType: "global"
	//   }
	//  }
	// }
	cloudConfig: {
		type: "cloudinit:Config"
		properties: {
			base64Encode: false
			gzip:         false
			parts: [{
				contentType: "text/x-shellscript"
				content: "Fn::ReadFile": "./cloud-config/1-bootstrap.sh"
			}]
		}
	}

	globalIp: {
		type: "equinix-metal:ReservedIpBlock"
		properties: {
			projectId: "${projectId}"
			type:      "global_ipv4"
			quantity:  1
		}
	}

	(#CoreDnsDevice & {name: "EU", metro: "am"}).resources
	(#CoreDnsDevice & {name: "US", metro: "da"}).resources
	(#CoreDnsDevice & {name: "AS", metro: "ty"}).resources
}

#CoreDnsDevice: {
	name:  string
	metro: string

	resources: {
		"device\(name)": {
			type: "equinix-metal:Device"
			properties: {
				plan:            "c3.small.x86"
				operatingSystem: "ubuntu_20_04"
				projectId:       "${projectId}"
				"metro":         metro
				userData:        "${cloudConfig.rendered}"
				customData: """
					{
					\"globalIp\": \"${globalIp.address}\"
					}
					"""
			}
		}

		"ipAttachment\(name)": {
			type: "equinix-metal:IpAttachment"
			options: deleteBeforeReplace: true
			properties: {
				cidrNotation: "${globalIp.cidrNotation}"
				deviceId:     "${device\(name).id}"
			}
		}

		"bgpSession\(name)": {
			type: "equinix-metal:BgpSession"
			properties: {
				addressFamily: "ipv4"
				deviceId:      "${device\(name).id}"
			}
		}
	}
}
