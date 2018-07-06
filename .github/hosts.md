# Manage hosts

## Create

VM Proxmox config tab:

![Create host](images/create_host.png)

OS tab with build from network (default):

![Build from network](images/create_host_os_network.png)

Network interface tab:

![Interface](images/create_host_interface.png)

Identifier is required. You must set `net[n]` with n an integer.

## Update

Update config is available.

## Clone images

You can also change a host in an image, i.e. a [template](https://pve.proxmox.com/wiki/Qemu/KVM_Virtual_Machines#qm_templates) in Proxmox.
You update a host. You check the box `Create image?` to true and save it:

![Update host to template](images/update_host_to_template.png)

The image is then available in the list of the create image form.

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

And you can check it in Proxmox wbe interface too:

![List VMs in Proxmox](images/proxmox_vms.png)

## Show a host

VM tab when vm is a template. `Templated?` is true:

![Show VM templated](images/show_host_templated.png)

VM tab when vm is not a template. `Templated?` is false:

![Show VM not templated](images/show_host.png)

## Start, stop VM

You can start and stop a vm:

![Running](images/running_vm.png)

You can not run a template vm.

## Console

When vm is running, you can open a noVNC console on it:

![Console](images/vnc_console.png)

![Console2](images/vnc_console2.png)