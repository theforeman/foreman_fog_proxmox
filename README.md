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

### From gem

See complete details in [plugin installation from gem](https://theforeman.org/plugins/#2.3AdvancedInstallationfromGems)

Here is a Debian sample:

* Install foreman 1.17 with [foreman-installer](https://theforeman.org/manuals/1.17/index.html#2.1Installation)
* Use only foreman user (**not root!**)
* In /usr/share/foreman/bundler.d directory, add Gemfile.local.rb file and add this line in it:

```ruby
gem 'the_foreman_proxmox'
```

* Install the plugin:

```shell
/usr/bin/foreman-ruby /usr/bin/bundle install
```

* Restart the server:

```shell
touch ~foreman/tmp/restart.txt
```

See complete details in [plugin installation from gem](https://theforeman.org/plugins/#2.3.2Debiandistributions)

You can see it in about foreman page:

![About resources](.github/images/about_resources.png)
![About greffon](.github/images/about_greffon.png)

### From OS packages

Deb, rpm: work in progress...

Please see the Foreman manual for complete instructions:

* [Foreman: How to Install a Plugin](http://theforeman.org/manuals/latest/index.html#6.1InstallaPlugin)

## Usage

* [Compute resource](.github/compute_resource.md)
* [Manage hosts](.github/hosts.md)

## Development

### Prerequisites

You need a Proxmox VE >= 5.1 server running.

You also need nodejs in your dev machine to run webpack-dev-server.

### Platform

* Fork this github repo.
* Clone it on your local machine
* Install foreman v1.17 on your machine:

```shell
git clone https://github.com/theforeman/foreman
git checkout tags/1.17
```

* Create a Gemfile.local.rb file in foreman/bundler.d/
* Add this line:

```ruby
gem 'the_foreman_proxmox', :path => '/your_path_to/foreman_proxmox'
```

* In foreman directory, install dependencies:

```shell
bundle install
```

* Configure foreman settings:

```shell
cp config/settings.yaml.example config/settings.yaml
```

* Install foreman database (sqlite is default in rails development):

```shell
cp config/database.yaml.example config/database.yaml
bundle exec rake db:migrate
bundle exec rake db:seed
```

* You can reset admin password if needed:

```shell
bundle exec rake permissions:reset
```

* In foreman directory, after you modify the_foreman_proxmox specific assets (proxmox.js, etc) you have to precompile it:

```shell
bundle plugin:assets:precompile[the_foreman_proxmox]
```

* In foreman directory, run rails server:

```shell
rails server
```

* In foreman directory, run in a new terminal the webpack-dev-server:

```shell
./node_modules/.bin/webpack-dev-server --config config/webpack.config.js
```

See details in [foreman plugin development](https://projects.theforeman.org/projects/foreman/wiki/How_to_Create_a_Plugin)

## Contributing

You can reach the [contributors](CONTRIBUTORS.md).
Bug reports and pull requests are welcome on GitHub at [ForemanProxmox](https://github.com/tristanrobert/foreman_proxmox). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Please read [how to contribute](CONTRIBUTING.md).

## License

The code is available as open source under the terms of the [GNU Public License v3](LICENSE).

## Code of Conduct

Everyone interacting in the ForemanProxmox project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).