# BTL-GCPhybridncc

This repo deploys all resources EXCEPT the BTL-core and BTL-spoke1 (refer to diagram below).
The repo is to simulate connecting an Aviatrix environment to an existing GCP 'brownfield' environment and facilitating connectivity
between the environments.   Document references are at the bottom of this page.


## Architecture
![Architecture](https://github.com/patelavtx/LabShare/blob/main/BTL-Hybridgcpncc.PNG)


## Overview
+ Core GCP transit has 'transit_enable_multi_tier_transit : true'  to allow for route propgation in Aviatrix without having to 'full-mesh' peer.
+ The 'MTT transit' facilitates the integration with GCP NCC (route reflector) and native GCP routing constructs to allow for route exchange.+
+ The 'MTT transit' also has transit_enable_multi_tier_transit : true
+ 'gcpnative.tf' builds the 'native GCP' environment  (i.e. Network1 and Network2 plus resources - CR, HAVPN and peering)
+ 'avtx-mtt.tf' builds the Aviatrix transit, NCC, NCC spoke association and Network2 CR peering 
+ 'gcp-nativevm.tf'  is added for convenience to add GCP vms in the native GCP networks and is optional (rename file extension to anything other that 'tf', terraform will ignore)

**Note/.**
+ 'MTT transit has 'route approval' enabled, (safeguard / control for allowing routes to propagate into Avtx), doesn't need to be set, but good example of controlled setting
**This means that routes from 'gcp native' need to be manually allowed:  Controller > MCT > Approval > 'select MTT transit' > Gateway Learned CIDR Lists**


## Example of adding GCP vm using 'gcloud'

This example shows adding a GCP VM to the 'BTL-spoke1' GCP spoke by leveraging the GCP 'gcloud' API  :
```


**>> Add VM in gcpspoke1 <<
**
gcloud compute firewall-rules create allow-ssh --direction=INGRESS --priority=1000 --network=gcpspoke1 --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create allow-http --direction=INGRESS --priority=1000 --network=gcpspoke1 --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create allow-icmp --direction=INGRESS --priority=1000 --network=gcpspoke1 --action=ALLOW --rules=icmp --source-ranges=0.0.0.0/0


gcloud compute instances create gcpspoke1-vm --network gcpspoke1 --subnet gcpspoke1 --zone europe-west2-a
```



## Pre-requisites / Suggested settings

+  BTL-core (Aviatrix transit core deployed)  with "transit_enable_multi_tier_transit : true (transit.yaml),  'MTT transit will peer with this core'
+  BTL-spoke1 (optional) -  help test out 'end-to-end' connectivity to brownfield (native GCP network)




## Details

**Terraform**

+  The Terraform code has the reference links added to the appropriate resource blocks used.




### Documentation Reference:

**GCP CloudVPN + NCC**
https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview

https://cloud.google.com/network-connectivity/docs/vpn/deprecations/classic-vpn-deprecation   (classic vpn is an option, but not as flexible and is being deprecated)

https://cloud.google.com/network-connectivity/docs/vpn/concepts/classic-topologies


**Aviatrix Multi-Tier-Transit (MTT)**
https://read.docs.aviatrix.com/HowTos/transit_advanced.html#multi-tier-transit



## Example of *tfvars 

+ These can be passed to the TFC workspace as variables or variable sets.  
+ Note/.  During the TFC workspace connection to the GH repo, you will get the options to add a values to variables specified in the 'variables.tf' file that do not have a 'default' value, recommend this is done prior to running the code.  
+ Other variables that have a default setting can be overridden using 'variables' or 'variable sets' and should not affect the running of the code if not done.


Example of 

```
#Controller Details:
avtx_controllerip = ""
avtx_admin_user = ""
avtx_admin_password = ""

gcp_project = ""
project = ""
account = ""

```



## Validated environment
```
Terraform v1.3.6
on linux_amd64 (WSL) and TFC workspace
+ provider aviatrixsystems/aviatrix v3.0.1 (tested v3.1.0 + controller 7.1)

```

## providers.tf
```
terraform {
  required_providers {
    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = "~>3.0.1"
    }
  }
}

