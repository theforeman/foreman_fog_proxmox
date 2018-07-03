![ForemanProxmox](.github/images/foremanproxmox.png)

[![Build Status](https://travis-ci.com/tristanrobert/foreman_proxmox.svg?branch=master)](https://travis-ci.com/tristanrobert/foreman_proxmox)
[![Maintainability](https://api.codeclimate.com/v1/badges/922162c278e0fa9207ba/maintainability)](https://codeclimate.com/github/tristanrobert/foreman_proxmox/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/922162c278e0fa9207ba/test_coverage)](https://codeclimate.com/github/tristanrobert/foreman_proxmox/test_coverage)

# ForemanProxmox

[Foreman](http://theforeman.org/) plugin that adds [Proxmox](https://www.proxmox.com/en/proxmox-ve) compute resource: managing virtual machines and containers using the [fog-proxmox](https://github.com/fog/fog-proxmox) module.

It is intended to satisfy this [feature](http://projects.theforeman.org/issues/2186).

## Compatibility

Tested with:

* Foreman = 1.17.1
* Fog-proxmox >= 0.4.0

## Installation

Please see the Foreman manual for appropriate instructions:

* [Foreman: How to Install a Plugin](http://theforeman.org/manuals/latest/index.html#6.1InstallaPlugin)

## Screenshots

![Compute resource](.github/images/compute_resource.png)
![Show vms of compute resource](.github/images/vms_compute_resource.png)
![Compute profile](.github/images/compute_profile_small.png)
![Create host](.github/images/create_host.png)
![List hosts](.github/images/hosts.png)
![Show host](.github/images/show_host.png)
![VNC Console](.github/images/vnc_console.png)
![VNC Console 2](.github/images/vnc_console2.png)

## Development

You need a Proxmox VE >= 5.1 server running.

* Fork this github repo.
* Clone it on your local machine

To install the plugin with foreman in a Docker container, move to the source code:

```shell
cd foreman_proxmox
```

Build a docker container:

```shell
sudo docker build -t foreman .
```

If you are behind a proxy http server, add:

```shell
--build-arg http_proxy=http://<user>:<password>@<ip>:<port>
...
```

Run it:

```shell
sudo docker run -it -p 3808:5000 --name foreman foreman
```

Access container's bash console:

```shell
sudo docker exec -it foreman bash
```

The docker container use ruby 2.3.7, latest nodejs 8.x (8.11.2) and foreman 1.17.1.

If you want to debug live. You have to clone foreman 1.17.1 repo and install foreman_proxmox plugin as gem. 
See [how to create a foreman plugin](https://projects.theforeman.org/projects/foreman/wiki/How_to_Create_a_Plugin)

## Contributing

You can reach the [contributors](CONTRIBUTORS.md).
Bug reports and pull requests are welcome on GitHub at [ForemanProxmox](https://github.com/tristanrobert/foreman_proxmox). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Please read [how to contribute](CONTRIBUTING.md).

## License

The code is available as open source under the terms of the [GNU Public License v3](LICENSE).

## Code of Conduct

Everyone interacting in the ForemanProxmox project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).