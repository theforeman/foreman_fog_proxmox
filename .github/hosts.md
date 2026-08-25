# Manage hosts

## Create

Nodes reported offline are excluded from new placement choices and node-local
metadata queries. Saved offline node selections remain visible with a warning
rather than being replaced automatically. Choose an available node before
provisioning; an explicitly requested node is still attempted through the API
because its reported status may be stale.

Editing a host or compute profile whose selected node is offline is not fully
supported: Fog may query that node's task API while constructing the form's VM
object, which can prevent the form from rendering. Profiles without a VM ID
also need an available node to generate defaults. Preserving a saved node
selection does not guarantee that its form can open while the node is unreachable.

You first choose VM type between a container or a server.

The form automatically changes.

Server VM Proxmox config tab:

![Create host server](images/create_host_sever.png)

Advanced options could also be modified in Server VM Proxmox config tab.

N.B.: There's a bug in [foreman/webpack/assets/javascripts/jquery.ui.custom_spinners.js](https://projects.theforeman.org/issues/25111) file. The minimum counter spinner is set to `1` and not `0`. It is used in device disk storage field so if you put `0`, it could show `1` instead.

Main options:

![Create host](images/create_host_advanced_main_options.png)

CPU options:

![Create host](images/create_host_advanced_cpu.png)

Memory options:

![Create host](images/create_host_advanced_memory.png)

You can add/update/remove 3 types of storages:

Hard disk (any),

CDROM (only once):

![Create host](images/create_host_volume_cdrom.png)

Cloud-init (only once):

![Create host](images/create_host_volume_cloud_init.png)

And when a cloud-init drive has been saved (with the host) then you can update cloud-init options:

![Create host](images/create_host_advanced_cloud_init.png)

OS options:

![Create host](images/create_host_advanced_os.png)

OS tab with build from network (default):

![Build from network](images/create_host_os_network.png)

Network server interface tab:

![Interface](images/create_host_interface.png)

Identifier is required. You must set `net[n]` with n an integer.
If not, a default one is set for you.

The container form slightly differs from the server one:

* OS template is required
* advanced options are slightly different

Container VM Proxmox config tab:

![Create host container](images/create_host_container.png)

You can add (many) mount points:

![Create host container](images/create_host_container_volume_mp.png)

Network interface container tab:

![Interface](images/create_host_container_interface.png)

## Update

Update config is available.

## Resource selections

Changing the selected node updates the available storage, media, and bridges.
Existing selections that are unavailable on the new node remain visible and
must be resolved before saving. Select an available resource, return to the
original node, or remove the affected device.

For host network interfaces, open the interface's edit dialog to correct an
unavailable bridge. If resource availability cannot be checked, reload the form
to retry.

## Delete

VM lookup skips nodes reported offline, but still finds VMs on available nodes.
If the VM is not found and any nodes were skipped, deletion fails explicitly:
the VM might still exist on an unsearched node. This can also block deletion of
a host whose VM is already gone until all nodes can be searched. API lookup
failures likewise do not count as confirmation that the VM is absent.

Cleanup after failed creation uses the newly created VM directly, rather than
searching the cluster again, so a stale offline status does not prevent the
cleanup attempt. Its current power and HA state is refreshed on its known node
before deletion; refresh failures are reported rather than using stale state.
New clones are also loaded from their known node, and remain eligible for cleanup
if loading the clone fails after cloning succeeds.

## Clone images

You can also change a host (server or container) into an image, i.e. a [template](https://pve.proxmox.com/wiki/Qemu/KVM_Virtual_Machines#qm_templates) in Proxmox.
You update a host. You check the box `Create image?` to true and save it. Here is container template sample:

![Update host to template](images/update_host_to_template.png)

The image is then available in the list of compute resource images tab:

![Compute resources images](images/compute_resource_images.png)

You create an image from your compute ressource:

![Create image with templates available](images/create_image_with_templates.png)

If previously you didn't created a template vm, the list of vmids is replaced by a single input:

![Create image when no template is available](images/create_image_no_templates.png)

It is not recommended to create an image without a valid vmid template in proxmox.

Then you can make linked clones of this image. To do so, you create a new host and in OS tab you choose build from image and choose the available image:

![Build from image](images/create_host_os_image.png)

The the vm is cloned by proxmox in a new VM. The name starts with `Copy of image-name`.

## List hosts

You can list hosts in foreman:

![List hosts](images/list_hosts.png)

And you can check it in Proxmox Web interface too:

![List VMs in Proxmox](images/proxmox_vms.png)

## Show a host

VM (container) tab when vm is a template. `Templated?` is true:

![Show VM templated](images/show_host_templated.png)

VM (server) tab when vm is not a template. `Templated?` is false:

![Show VM not templated](images/show_host.png)

## Start, stop VM

You can start and stop a vm:

![Running](images/running_vm.png)

You can not run a template vm.

## Console

When vm is running, you can open a noVNC console on it:

![Console](images/vnc_console.png)

![Console2](images/vnc_console2.png)
