# Changelog

## [0.17.2](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.17.1...v0.17.2) (2025-02-25)


### Bug Fixes

* Drop EL8 from packit config ([#388](https://github.com/theforeman/foreman_fog_proxmox/issues/388)) ([6da5e52](https://github.com/theforeman/foreman_fog_proxmox/commit/6da5e5269fdc9188bd1b34749b6f11c1b859d82e))
* Support Rails 7.0 ([#400](https://github.com/theforeman/foreman_fog_proxmox/issues/400)) ([a7b5c62](https://github.com/theforeman/foreman_fog_proxmox/commit/a7b5c6281f18d780f29094f77573c8a279ef3dc4))

## [0.17.1](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.17.0...v0.17.1) (2024-11-06)


### Bug Fixes

* Only remove network interface section if compute resource is proxmox ([#371](https://github.com/theforeman/foreman_fog_proxmox/issues/371)) ([04082e4](https://github.com/theforeman/foreman_fog_proxmox/commit/04082e4e57573b5f708bc8945e70edca81774e12))
* Readd storage to host's compute details ([#373](https://github.com/theforeman/foreman_fog_proxmox/issues/373)) ([5dea655](https://github.com/theforeman/foreman_fog_proxmox/commit/5dea65590299b1187e88e333b8b8782c53e5cac9))

## [0.17.0](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.16.2...v0.17.0) (2024-10-02)


### Features

* Add Zeitwerk loader support ([#355](https://github.com/theforeman/foreman_fog_proxmox/issues/355)) ([c237bc0](https://github.com/theforeman/foreman_fog_proxmox/commit/c237bc012ce5cc965ce74ad97c7ae62296e0418a))

## [0.16.2](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.16.1...v0.16.2) (2024-10-02)


### Features

* Add provisioning template for cloudinit user data ([#345](https://github.com/theforeman/foreman_fog_proxmox/issues/345)) ([3aa8b13](https://github.com/theforeman/foreman_fog_proxmox/commit/3aa8b1368675bc75cb1fbf35ee6135f49e5a59a6))


### Bug Fixes

* Add cpu types to qemu server ([#348](https://github.com/theforeman/foreman_fog_proxmox/issues/348)) ([c0cb16b](https://github.com/theforeman/foreman_fog_proxmox/commit/c0cb16b584cca158ad3b1303d421fcafe04b0d12)), closes [#347](https://github.com/theforeman/foreman_fog_proxmox/issues/347)
* Fix network interface capitalize issue ([#338](https://github.com/theforeman/foreman_fog_proxmox/issues/338)) ([7c285cb](https://github.com/theforeman/foreman_fog_proxmox/commit/7c285cb6e9293d0c484d1d79e181f56a30584588))
* fixes react UI issues which prevented host creation and edit ([#337](https://github.com/theforeman/foreman_fog_proxmox/issues/337)) ([a40c106](https://github.com/theforeman/foreman_fog_proxmox/commit/a40c1061f7a5a71dd8f13279ce3ed43fb97e0d72))
* Prevent mount point volid to change on host edit ([#341](https://github.com/theforeman/foreman_fog_proxmox/issues/341)) ([c552fd2](https://github.com/theforeman/foreman_fog_proxmox/commit/c552fd20b8be20b81a25b09e173ce9f91b3eec19))
* Update CPU types list to provide all available types in Proxmox server. ([#350](https://github.com/theforeman/foreman_fog_proxmox/issues/350)) ([a7531fd](https://github.com/theforeman/foreman_fog_proxmox/commit/a7531fdcec2168567e11904db5776d03ce36b844))


### Miscellaneous Chores

* release 0.16.2 ([#354](https://github.com/theforeman/foreman_fog_proxmox/issues/354)) ([1f44d6f](https://github.com/theforeman/foreman_fog_proxmox/commit/1f44d6f92ed330f500f39db32c9cee4f96eb04f0))

## [0.16.1](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.16.0...v0.16.1) (2024-07-24)


### Bug Fixes

* Update package.json ([#335](https://github.com/theforeman/foreman_fog_proxmox/issues/335)) ([595fa60](https://github.com/theforeman/foreman_fog_proxmox/commit/595fa60c04654571a2cacfb894440c63a61df45a))

## [0.16.0](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.15.1...v0.16.0) (2024-07-23)


### ⚠ BREAKING CHANGES

* Move from jquery to react js ([#331](https://github.com/theforeman/foreman_fog_proxmox/issues/331))

### Features

* Move from jquery to react js ([#331](https://github.com/theforeman/foreman_fog_proxmox/issues/331)) ([3c18767](https://github.com/theforeman/foreman_fog_proxmox/commit/3c18767237c74bc61c71871506c698ab220b55a1)), closes [#333](https://github.com/theforeman/foreman_fog_proxmox/issues/333)


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
