![ForemanProxmox](foremanproxmox.png)

# Foreman::Proxmox

[Foreman](http://theforeman.org/) plugin that manages [Proxmox](https://www.proxmox.com/en/proxmox-ve) virtual machines and containers using the [fog-proxmox](https://github.com/tristanrobert/fog-proxmox) module.

It is intended to satisfy this [feature](http://projects.theforeman.org/issues/2186)

## Installation

Please see the Foreman manual for appropriate instructions:

* [Foreman: How to Install a Plugin](http://theforeman.org/manuals/latest/index.html#6.1InstallaPlugin)

## Usage

This is not yet a stable version. I recommend you not to use it in production.

Work is still in progress...

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

## Contributing

You can reach the [contributors](CONTRIBUTORS.md).
Bug reports and pull requests are welcome on GitHub at [ForemanProxmox](https://github.com/tristanrobert/foreman_proxmox). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Please read [how to contribute](CONTRIBUTING.md).

## License

The code is available as open source under the terms of the [GNU Public License v3](LICENSE).

## Code of Conduct

Everyone interacting in the ForemanProxmox project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).