# Changelog

## [0.15.1](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.15.0...v0.15.1) (2024-02-23)


### Bug Fixes

* Disk controller setup does not add hard disk other than virtio0 ([#304](https://github.com/theforeman/foreman_fog_proxmox/issues/304)) ([2fcf04c](https://github.com/theforeman/foreman_fog_proxmox/commit/2fcf04c84d2071c9ab3b15f1d4004da4e0567903))

## [0.15.0](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.14.3...v0.15.0) (2023-11-15)


### Features

* Add Cloudinit support using iso image ([#294](https://github.com/theforeman/foreman_fog_proxmox/issues/294)) ([55e22a1](https://github.com/theforeman/foreman_fog_proxmox/commit/55e22a1f58c78371870a25aae9d14f62a096a42d)), closes [#296](https://github.com/theforeman/foreman_fog_proxmox/issues/296)
* Added option to associate individual vm to host ([#300](https://github.com/theforeman/foreman_fog_proxmox/issues/300)) ([ccbdb06](https://github.com/theforeman/foreman_fog_proxmox/commit/ccbdb0664d32e48aba47847a2a89bba7a2ba54f3)), closes [#301](https://github.com/theforeman/foreman_fog_proxmox/issues/301)


### Bug Fixes

* Fixes DNS issue for host deployment with nic identifier ([#293](https://github.com/theforeman/foreman_fog_proxmox/issues/293)) ([abd790a](https://github.com/theforeman/foreman_fog_proxmox/commit/abd790a7f286e4fffc4d80a4415af2a44c9baa0c)), closes [#292](https://github.com/theforeman/foreman_fog_proxmox/issues/292)
* Increase visibility of Main Options ([#287](https://github.com/theforeman/foreman_fog_proxmox/issues/287)) ([1b5fd16](https://github.com/theforeman/foreman_fog_proxmox/commit/1b5fd16f73a18adb521d661db555bcae5b20ff0c)), closes [#288](https://github.com/theforeman/foreman_fog_proxmox/issues/288)

## [0.14.3](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.14.2...v0.14.3) (2023-08-25)


### Bug Fixes

* enable kvm option by default ([#286](https://github.com/theforeman/foreman_fog_proxmox/issues/286)) ([0e015ae](https://github.com/theforeman/foreman_fog_proxmox/commit/0e015ae2843d5e41a202d2bf200a6780eab5e5ad)), closes [#289](https://github.com/theforeman/foreman_fog_proxmox/issues/289)

## [0.14.2](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.14.1...v0.14.2) (2022-12-16)


### Bug Fixes

* VLAN Tag is not transmitted to the proxmox api at vm creation ([4e22c5b](https://github.com/theforeman/foreman_fog_proxmox/commit/4e22c5b9e761aeb63707c184645b13fa0f7826c6)), closes [#228](https://github.com/theforeman/foreman_fog_proxmox/issues/228)

## [0.14.1](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.14.0...v0.14.1) (2022-12-14)


### Bug Fixes

* Create host fails on 2.5.2 ([0eaab9a](https://github.com/theforeman/foreman_fog_proxmox/commit/0eaab9ae118e3ab7ee7b0b064c45cba1ab0438f7)), closes [#207](https://github.com/theforeman/foreman_fog_proxmox/issues/207)
