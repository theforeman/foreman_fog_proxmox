# Changelog

## [0.15.2](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.15.1...v0.15.2) (2024-07-16)


### Bug Fixes

* container templates to create image in compute resource ([#327](https://github.com/theforeman/foreman_fog_proxmox/issues/327)) ([8f86f79](https://github.com/theforeman/foreman_fog_proxmox/commit/8f86f79f74606be8b0ccfc6ec89f2f1b729f68f4)), closes [#328](https://github.com/theforeman/foreman_fog_proxmox/issues/328)

## [0.15.1](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.15.0...v0.15.1) (2024-04-05)


### Bug Fixes

* Advanced options are not set in host creation ([#317](https://github.com/theforeman/foreman_fog_proxmox/issues/317)) ([5bcd877](https://github.com/theforeman/foreman_fog_proxmox/commit/5bcd87796a8f26725a79397904911252b5991f6f)), closes [#310](https://github.com/theforeman/foreman_fog_proxmox/issues/310)
* auto set vmid when creating host from Foreman API ([#312](https://github.com/theforeman/foreman_fog_proxmox/issues/312)) ([edc4a0c](https://github.com/theforeman/foreman_fog_proxmox/commit/edc4a0c93a5a1d5c0ed336174147a62cbc241e86)), closes [#254](https://github.com/theforeman/foreman_fog_proxmox/issues/254)
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
