# Compute resource

## Create compute resource

You create a proxmox compute resource and set:

* the API REST URL, e.g: http://[host]:8006/api2/json
* username with sufficient privilegies to create vm within his realm, e.g: root@pam. Don't forget the @!

Then you can choose between two authentication modes:

Access ticket (Default):

* user password

Or user token:

* user token id with sufficient privilegies to create vm within his realm
* user token value

You can add SSL certificates too: check `SSL verify peer` and copy and paste the two cluster certificates: root and pve

Test if connection works, then save it.

![Compute resource](images/compute_resource.png)

Certificates can be copy and paste from your provider:

![Proxmox certificates](images/proxmox_certificates.png)

You can see vm associated with proxmox provider:

![Show vms of compute resource](images/vms_compute_resource.png)

You can see it in about page:

![About compute](images/about_compute.png)

You can see in welcome page this widget which shows node average load through time:

![Widget](images/widget_node_loadavg.png)

## Host group, profiles

To ease hosts management you can create a host group.

You can create profiles (server and container). Here is server sample:

![Compute profile](images/compute_profile_server.png)

Here is container sample:

![Compute profile](images/compute_profile_container.png)

You can show compute resource details:

![Compute resources details](images/compute_resource_show.png)

Then you can list profiles:

![Compute profile](images/list_profiles.png)

## Associated vms

You can list VMs associated to your proxmox compute resource:

![VMs associated to your proxmox compute resource](images/vms_compute_resource.png)

## Associated images

You can list images associated to your proxmox compute resource:

![Images associated to your proxmox compute resource](images/list_images.png)