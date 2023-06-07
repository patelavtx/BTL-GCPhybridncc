# BTL-GCPHAvpn-NCC-Avtx

This repo deploys all resources EXCEPT the BTL-core and BTL-spoke1 (refer to diagram below).
The repo is to simulate connecting an Aviatrix environment to an existing GCP 'brownfield' environment and facilitating connectivity
between the environments.

## Pre-requisites

+  BTL-core (Aviatrix transit core deployed)
+  BTL-spoke1 (suggested this is deployed to test out 'end-to-end' connectivity to brownfield resources)



## DFW Enforcement

***Note/. The behaviour when 'Distributed Firewall' > Rules in place ***

+ Policy Rules in place with  NO enforcement (implicit deny for inter spoke connectivity); intra spoke connectivity is fine
+ Policy Rules in place with enforcement enabled;  inter spoke connectivity will be dependent upon the rules in place.
+ No policy rules added then inter spoke connectivity is fine.



##  Azurevms.tf

***(login/password =  ubuntu/Aviatrix123#)***

+ Example of deploying VMs
 Azurevms.tf has been added that can be used to easily introduce vms for basic testing.
 (if this is not required, just rename the file extension to anything other than 'tf' to ensure terraform does not read and deploy it)


##  GCPvms

 A similar terraform file will be added later to include multi-cloud dfw testing.

However, GCP vms can be deployed using Terraform referencing this:
 https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
 
 Alternatively, deploy vms manually via the GCP console/portal.


## Details

**Terraform**

+  Smartgroups >         
**https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_smart_group**

+  DFW policies>         
**https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_distributed_firewalling_policy_list**

+  Enable intravnet DFW> 
**https://registry.terraform.io/providers/AviatrixSystems/aviatrix/latest/docs/resources/aviatrix_distributed_firewalling_intra_vpc**



### Documentation Reference:

**https://docs.aviatrix.com/copilot/latest/network-security/secure-networking-components.html?expand=true**

**https://aviatrix.atlassian.net/wiki/spaces/AVXPM/pages/1634697244/Micro-Segmentation+Deployment**

**https://aviatrix.atlassian.net/wiki/spaces/AVXPM/pages/1766457424/Intra-VNet+Micro-segmentation#How-to-Enable-Intra-VNet-Micro-segmentation-feature**

**https://registry.terraform.io/modules/terraform-aviatrix-modules/mc-spoke/aviatrix/latest   (spoke module)**





### Requirements:

+ The Distributed Firewalling feature requires the Aviatrix Secure Networking Platform 2208-Universal 24x7 Support subscription offer license to be enabled.
(Home > Settings > Licensing ; Copilot)


```

- User must be running Controller release 7.0 or above 

- By Default Intra-VNet Micro-segmentation feature is disabled on Azure VNets (see screenshot further down)

- Only VNets running Aviatrix Spoke Gateways will show up in the list to be enabled for this feature

- Feature is enabled per VNet

- Once Intra-VNet Distributed Firewalling Feature is enabled, any ASG or NSGs attached to the instance or subnet will be removed

All customer configured ASG and NSGs will be saved in Aviatrix Database, in case user deletes the rules or disabled the feature- all default settings will be pushed back
```



## Example of *tfvars 
```
#Controller Details:
avtx_controllerip = ""
avtx_admin_user = ""
avtx_admin_password = ""

```




## Architecture
![Architecture](https://github.com/patelavtx/LabShare/blob/main/BTL-dfw.png)



## Example of Variables in TFC
![TFVARS](https://github.com/patelavtx/LabShare/blob/main/BTL-dfw-tfvars.png)


## Enable Intravnet Segmentation (Azure only currently)
![IntraVnet](https://github.com/patelavtx/LabShare/blob/main/BTL-dfw-intravnet.png)




## Validated environment
```
Terraform v1.3.6
on linux_amd64 (WSL) and TFC workspace
+ provider aviatrixsystems/aviatrix v3.0.1

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

