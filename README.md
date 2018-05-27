![ForemanProxmox](foremanproxmox.png)

# Foreman::Proxmox

[Foreman](http://theforeman.org/) plugin that manages [Proxmox](https://www.proxmox.com/en/proxmox-ve) virtual machines and containers using the [fog-proxmox](https://github.com/tristanrobert/fog-proxmox) module.

It is intended to satisfy this [feature](http://projects.theforeman.org/issues/2186)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'foreman_proxmox'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install foreman_proxmox

## Usage

This is not yet a stable version. I recommend you not to use it in production.

Work is still in progress...

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

You can reach the [contributors](CONTRIBUTORS.md).
Bug reports and pull requests are welcome on GitHub at [ForemanProxmox](https://github.com/tristanrobert/foreman_proxmox). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Please read [how to contribute](CONTRIBUTING.md).

## License

The code is available as open source under the terms of the [GNU Public License v3](LICENSE).

## Code of Conduct

Everyone interacting in the ForemanProxmox project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).