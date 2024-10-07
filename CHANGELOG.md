# Changelog

## [0.17.0](https://github.com/theforeman/foreman_fog_proxmox/compare/v0.16.2...v0.17.0) (2024-10-02)


### Features

* Add Zeitwerk loader support ([#355](https://github.com/theforeman/foreman_fog_proxmox/issues/355)) ([c237bc0](https://github.com/theforeman/foreman_fog_proxmox/commit/c237bc012ce5cc965ce74ad97c7ae62296e0418a))

## [0.16.2](https://github.com/btoneill/foreman_fog_proxmox/compare/v0.16.2...v0.16.2) (2024-10-07)


### ⚠ BREAKING CHANGES

* Move from jquery to react js ([#331](https://github.com/btoneill/foreman_fog_proxmox/issues/331))

### Features

* :lipstick: vm description used into profiles ([cea0452](https://github.com/btoneill/foreman_fog_proxmox/commit/cea0452bce4fd255cff1fc8fa3d1c083b401568c))
* :sparkles: add ansible suitability ([43d6846](https://github.com/btoneill/foreman_fog_proxmox/commit/43d6846558a6858a40c21338a3e25a5ee3d3fdcd)), closes [#160](https://github.com/btoneill/foreman_fog_proxmox/issues/160)
* :sparkles: add bios selection in server vm form ([38f985f](https://github.com/btoneill/foreman_fog_proxmox/commit/38f985f4dc369921eec67d225f1978c18c7da924)), closes [#154](https://github.com/btoneill/foreman_fog_proxmox/issues/154)
* :sparkles: fixes [#180](https://github.com/btoneill/foreman_fog_proxmox/issues/180) devices boot order ([2990aec](https://github.com/btoneill/foreman_fog_proxmox/commit/2990aec02cadff63b69c9abd5e7274ffee2f0b97))
* Add Cloudinit support using iso image ([#294](https://github.com/btoneill/foreman_fog_proxmox/issues/294)) ([55e22a1](https://github.com/btoneill/foreman_fog_proxmox/commit/55e22a1f58c78371870a25aae9d14f62a096a42d)), closes [#296](https://github.com/btoneill/foreman_fog_proxmox/issues/296)
* add fog-proxmox 0.9 ([ffa4c15](https://github.com/btoneill/foreman_fog_proxmox/commit/ffa4c15b7ce921a100ad9408cd148169385bb8fb))
* Add provisioning template for cloudinit user data ([#345](https://github.com/btoneill/foreman_fog_proxmox/issues/345)) ([3aa8b13](https://github.com/btoneill/foreman_fog_proxmox/commit/3aa8b1368675bc75cb1fbf35ee6135f49e5a59a6))
* add proxmox 6 suitability ([1cd3715](https://github.com/btoneill/foreman_fog_proxmox/commit/1cd371574e0cd397cc53a1c646b95fced3a97c51))
* Add Zeitwerk loader support ([#355](https://github.com/btoneill/foreman_fog_proxmox/issues/355)) ([c237bc0](https://github.com/btoneill/foreman_fog_proxmox/commit/c237bc012ce5cc965ce74ad97c7ae62296e0418a))
* Added option to associate individual vm to host ([#300](https://github.com/btoneill/foreman_fog_proxmox/issues/300)) ([ccbdb06](https://github.com/btoneill/foreman_fog_proxmox/commit/ccbdb0664d32e48aba47847a2a89bba7a2ba54f3)), closes [#301](https://github.com/btoneill/foreman_fog_proxmox/issues/301)
* **container:** add ipv6 and gateway ([3432c0b](https://github.com/btoneill/foreman_fog_proxmox/commit/3432c0bc043c18c9a12f6e1ed6e9e6059323b7fc))
* fixes [#135](https://github.com/btoneill/foreman_fog_proxmox/issues/135) and [#136](https://github.com/btoneill/foreman_fog_proxmox/issues/136) ([ea5222e](https://github.com/btoneill/foreman_fog_proxmox/commit/ea5222e419d1c6fdf6c68f3f9cfa4d7d980bd3be))
* fixes [#143](https://github.com/btoneill/foreman_fog_proxmox/issues/143) add scsi controller ([53f8892](https://github.com/btoneill/foreman_fog_proxmox/commit/53f88922048a20ba431e2c99f81708afc016a844))
* fixes [#147](https://github.com/btoneill/foreman_fog_proxmox/issues/147) update api ([011e018](https://github.com/btoneill/foreman_fog_proxmox/commit/011e018ee97c800d6b25bb3599dd84a2dcd9adb8))
* **host:** fixes [#133](https://github.com/btoneill/foreman_fog_proxmox/issues/133) ([2d316cb](https://github.com/btoneill/foreman_fog_proxmox/commit/2d316cb10358233c1293db43bab53bb1040581f2))
* **interface:** add CIDR and DHCP nic options [#97](https://github.com/btoneill/foreman_fog_proxmox/issues/97) ([49f8566](https://github.com/btoneill/foreman_fog_proxmox/commit/49f85666b39681c4de1c229654ac16d7f6985925))
* Move from jquery to react js ([#331](https://github.com/btoneill/foreman_fog_proxmox/issues/331)) ([3c18767](https://github.com/btoneill/foreman_fog_proxmox/commit/3c18767237c74bc61c71871506c698ab220b55a1)), closes [#333](https://github.com/btoneill/foreman_fog_proxmox/issues/333)
* rename balloon memory ([ed86739](https://github.com/btoneill/foreman_fog_proxmox/commit/ed8673970bc72df367eff15937cfda1354502a97))
* **renew ticket:** refactor and fix [#77](https://github.com/btoneill/foreman_fog_proxmox/issues/77) ([1a48b95](https://github.com/btoneill/foreman_fog_proxmox/commit/1a48b9554c97cfb28440dd795804fa4c64dca3a7))
* start on boot after vm creation [#80](https://github.com/btoneill/foreman_fog_proxmox/issues/80) ([04f12cd](https://github.com/btoneill/foreman_fog_proxmox/commit/04f12cd89415cc7262533a86eb18a48088680ecc))
* update fr and en translations ([8163e84](https://github.com/btoneill/foreman_fog_proxmox/commit/8163e847ef1590e4103272c9387a547b5e46a2b4))
* update translations ([570df04](https://github.com/btoneill/foreman_fog_proxmox/commit/570df0408a9421553df59567fdaab38ed93d55e5))


### Bug Fixes

* :art: refactor rubocop fixes ([1855008](https://github.com/btoneill/foreman_fog_proxmox/commit/18550080e4e2b23ea82949ced5916fe5a785d530))
* :bug: add ipv6 in import host ([a86c448](https://github.com/btoneill/foreman_fog_proxmox/commit/a86c44819a6a152b3f0566090f4216c04853e189))
* :bug: fix typo coreos type ([8bd6de7](https://github.com/btoneill/foreman_fog_proxmox/commit/8bd6de72bfc1f14c9b9fb24249d84fff6942a7a6)), closes [#158](https://github.com/btoneill/foreman_fog_proxmox/issues/158)
* :bug: fixes add many container mount points ([f131382](https://github.com/btoneill/foreman_fog_proxmox/commit/f131382d265944cda85bb5765a6dc5b0b2715f61))
* :bug: fixes permission declaration syntax ([abf20db](https://github.com/btoneill/foreman_fog_proxmox/commit/abf20db1600cef330af1fea6db5532379f15a471))
* :bug: fixes renamed routes permissions ([332ee5a](https://github.com/btoneill/foreman_fog_proxmox/commit/332ee5a6615ae90f9e627c8db8f3a153b669350e))
* :bug: fixes rollback destroy vm from uuid ([f08d358](https://github.com/btoneill/foreman_fog_proxmox/commit/f08d3588c375fd9c736c78551e996f8067c6de48))
* :bug: fixes routes permissions renamed ([781fb70](https://github.com/btoneill/foreman_fog_proxmox/commit/781fb70d43909979d17729e486b9c873a8f13368))
* :bug: fixes routes permissions renamed ([1aff672](https://github.com/btoneill/foreman_fog_proxmox/commit/1aff672af51f32bd21948d48ea6d59ae5733ca75))
* :bug: fixes showed version given by proxmox ([0ecdc7d](https://github.com/btoneill/foreman_fog_proxmox/commit/0ecdc7d2593d8603c1525c00ab286021e98a047f))
* :bug: fixes template server ([f42b5d0](https://github.com/btoneill/foreman_fog_proxmox/commit/f42b5d06db370208bd76d1afc11be6e9f006c851))
* :bug: fixes vm importation ([3075e3a](https://github.com/btoneill/foreman_fog_proxmox/commit/3075e3ae1595f1aaf1cd79b2592519bb51508fb2)), closes [#155](https://github.com/btoneill/foreman_fog_proxmox/issues/155)
* :bug: Fixes vm name provisioning with FQDN ([da8ffd6](https://github.com/btoneill/foreman_fog_proxmox/commit/da8ffd6f43de5d2a15e9fffbe60a85672bb5c1c4)), closes [#189](https://github.com/btoneill/foreman_fog_proxmox/issues/189)
* :bug: permission name ([45fd2c7](https://github.com/btoneill/foreman_fog_proxmox/commit/45fd2c7745521a1688f29bee0678558f1f154287))
* :bug: permission syntax ([6898447](https://github.com/btoneill/foreman_fog_proxmox/commit/6898447580b5ec98a55c2ad9f546a26847442417))
* :bug: update ip, dhcp and cidr ([7b2dbe8](https://github.com/btoneill/foreman_fog_proxmox/commit/7b2dbe8cc8d758c0cf068031697decd2abca01bd))
* :green_heart: permission name declared ([7e58218](https://github.com/btoneill/foreman_fog_proxmox/commit/7e5821895996a5fae5b650daec3c6f9d9d6d1216))
* [#126](https://github.com/btoneill/foreman_fog_proxmox/issues/126) and [#127](https://github.com/btoneill/foreman_fog_proxmox/issues/127) ([9ac7a58](https://github.com/btoneill/foreman_fog_proxmox/commit/9ac7a58f47784518be5af38d0bbfc3c38958e5f0))
* 41: list compute resource vm by node only ([75956dc](https://github.com/btoneill/foreman_fog_proxmox/commit/75956dc2dbe5ae650986b298087858f0c1a37b1f))
* 47: disk id unchanged ([3bc6f0e](https://github.com/btoneill/foreman_fog_proxmox/commit/3bc6f0e2ff353428330fff440d1ffe58febbb257))
* 48 - Many volumes creation ([e09ce36](https://github.com/btoneill/foreman_fog_proxmox/commit/e09ce36dbb648ddb77e6c159fb863fe4bbc5dc04))
* 50: many disks fix with controller set ([dbddb9e](https://github.com/btoneill/foreman_fog_proxmox/commit/dbddb9e22d0c53cd1bf71d4dd46934cf1ea2e8aa))
* Add cpu types to qemu server ([#348](https://github.com/btoneill/foreman_fog_proxmox/issues/348)) ([c0cb16b](https://github.com/btoneill/foreman_fog_proxmox/commit/c0cb16b584cca158ad3b1303d421fcafe04b0d12)), closes [#347](https://github.com/btoneill/foreman_fog_proxmox/issues/347)
* add proxmox 6.1+ compatibility ([aa41e68](https://github.com/btoneill/foreman_fog_proxmox/commit/aa41e68648f16499cc33b8bc54ebafbf6316053b))
* Advanced options are not set in host creation ([#317](https://github.com/btoneill/foreman_fog_proxmox/issues/317)) ([5bcd877](https://github.com/btoneill/foreman_fog_proxmox/commit/5bcd87796a8f26725a79397904911252b5991f6f)), closes [#310](https://github.com/btoneill/foreman_fog_proxmox/issues/310)
* auto set vmid when creating host from Foreman API ([#312](https://github.com/btoneill/foreman_fog_proxmox/issues/312)) ([edc4a0c](https://github.com/btoneill/foreman_fog_proxmox/commit/edc4a0c93a5a1d5c0ed336174147a62cbc241e86)), closes [#254](https://github.com/btoneill/foreman_fog_proxmox/issues/254)
* clone container from image [#116](https://github.com/btoneill/foreman_fog_proxmox/issues/116) ([7df5419](https://github.com/btoneill/foreman_fog_proxmox/commit/7df541916914e268d02196ee09874c97b982ead4))
* container templates to create image in compute resource ([#327](https://github.com/btoneill/foreman_fog_proxmox/issues/327)) ([8f86f79](https://github.com/btoneill/foreman_fog_proxmox/commit/8f86f79f74606be8b0ccfc6ec89f2f1b729f68f4)), closes [#328](https://github.com/btoneill/foreman_fog_proxmox/issues/328)
* Create host fails on 2.5.2 ([0eaab9a](https://github.com/btoneill/foreman_fog_proxmox/commit/0eaab9ae118e3ab7ee7b0b064c45cba1ab0438f7)), closes [#207](https://github.com/btoneill/foreman_fog_proxmox/issues/207)
* create server volume cache ([cd1ee6d](https://github.com/btoneill/foreman_fog_proxmox/commit/cd1ee6d362ec55152288561338710eb4926f9f17))
* delete server volume ([360a1eb](https://github.com/btoneill/foreman_fog_proxmox/commit/360a1eb4e87f934a64323ca4c66e470cc0fef5b9))
* Disk controller setup does not add hard disk other than virtio0 ([#304](https://github.com/btoneill/foreman_fog_proxmox/issues/304)) ([2fcf04c](https://github.com/btoneill/foreman_fog_proxmox/commit/2fcf04c84d2071c9ab3b15f1d4004da4e0567903))
* enable kvm option by default ([#286](https://github.com/btoneill/foreman_fog_proxmox/issues/286)) ([0e015ae](https://github.com/btoneill/foreman_fog_proxmox/commit/0e015ae2843d5e41a202d2bf200a6780eab5e5ad)), closes [#289](https://github.com/btoneill/foreman_fog_proxmox/issues/289)
* Fix network interface capitalize issue ([#338](https://github.com/btoneill/foreman_fog_proxmox/issues/338)) ([7c285cb](https://github.com/btoneill/foreman_fog_proxmox/commit/7c285cb6e9293d0c484d1d79e181f56a30584588))
* fixes [#118](https://github.com/btoneill/foreman_fog_proxmox/issues/118) ([e6f4ee6](https://github.com/btoneill/foreman_fog_proxmox/commit/e6f4ee6e97959c59300228394f0f22012376a937))
* fixes [#129](https://github.com/btoneill/foreman_fog_proxmox/issues/129) ([566254f](https://github.com/btoneill/foreman_fog_proxmox/commit/566254f2aa4e310aadfff5ff7c87b07f56795158))
* fixes [#139](https://github.com/btoneill/foreman_fog_proxmox/issues/139) memory and cpu server config ([56ac035](https://github.com/btoneill/foreman_fog_proxmox/commit/56ac035d0a29ae23c34e8e880594ca1227e021de))
* fixes [#149](https://github.com/btoneill/foreman_fog_proxmox/issues/149) http_proxy setting ([f44cef9](https://github.com/btoneill/foreman_fog_proxmox/commit/f44cef9ec2214d91fc0c651d6ada0a37c32eadb0))
* Fixes DNS issue for host deployment with nic identifier ([#293](https://github.com/btoneill/foreman_fog_proxmox/issues/293)) ([abd790a](https://github.com/btoneill/foreman_fog_proxmox/commit/abd790a7f286e4fffc4d80a4415af2a44c9baa0c)), closes [#292](https://github.com/btoneill/foreman_fog_proxmox/issues/292)
* fixes react UI issues which prevented host creation and edit ([#337](https://github.com/btoneill/foreman_fog_proxmox/issues/337)) ([a40c106](https://github.com/btoneill/foreman_fog_proxmox/commit/a40c1061f7a5a71dd8f13279ce3ed43fb97e0d72))
* fixes when vmid or vm nil ([514f6fd](https://github.com/btoneill/foreman_fog_proxmox/commit/514f6fdd365e61d4cf7092a6350a35ac8a985b77))
* foreman 2.5 suitability ([f216584](https://github.com/btoneill/foreman_fog_proxmox/commit/f216584fb36d58482613ec0a5160c79377ed1072)), closes [#199](https://github.com/btoneill/foreman_fog_proxmox/issues/199) [#205](https://github.com/btoneill/foreman_fog_proxmox/issues/205)
* Increase visibility of Main Options ([#287](https://github.com/btoneill/foreman_fog_proxmox/issues/287)) ([1b5fd16](https://github.com/btoneill/foreman_fog_proxmox/commit/1b5fd16f73a18adb521d661db555bcae5b20ff0c)), closes [#288](https://github.com/btoneill/foreman_fog_proxmox/issues/288)
* js es5 compatibility ([9150192](https://github.com/btoneill/foreman_fog_proxmox/commit/9150192d590273c0ca5153f5faf0cc0f0167df91))
* **js:** es5 syntax ([b5289a3](https://github.com/btoneill/foreman_fog_proxmox/commit/b5289a347cd55f98f0aa39853ae7207dbc3bd962))
* limit deface overrides to proxmox plugin [#87](https://github.com/btoneill/foreman_fog_proxmox/issues/87) ([a7f536f](https://github.com/btoneill/foreman_fog_proxmox/commit/a7f536f2918b32d9b6cc819a224e7ce261b55f69))
* no vms attached to compute resources ([d897e93](https://github.com/btoneill/foreman_fog_proxmox/commit/d897e93f478282c5707adfac8c28356b87f5a257))
* node profile ([605cb13](https://github.com/btoneill/foreman_fog_proxmox/commit/605cb13b476e02c151a1bed3e0e9368e9b285985))
* Prevent mount point volid to change on host edit ([#341](https://github.com/btoneill/foreman_fog_proxmox/issues/341)) ([c552fd2](https://github.com/btoneill/foreman_fog_proxmox/commit/c552fd20b8be20b81a25b09e173ce9f91b3eec19))
* **rubocop:** rails rules ([48d8a29](https://github.com/btoneill/foreman_fog_proxmox/commit/48d8a29f65914208927bfcf40bd73a8f4441befb))
* semver comparisons ([2463365](https://github.com/btoneill/foreman_fog_proxmox/commit/2463365f3d0de762988b2625ae7d8fe0f63543cd))
* update container vm interfaces ([9c3e012](https://github.com/btoneill/foreman_fog_proxmox/commit/9c3e01226d6a0fe99917a1c6a307ac85fafd8878))
* Update CPU types list to provide all available types in Proxmox server. ([#350](https://github.com/btoneill/foreman_fog_proxmox/issues/350)) ([a7531fd](https://github.com/btoneill/foreman_fog_proxmox/commit/a7531fdcec2168567e11904db5776d03ce36b844))
* Update package.json ([#335](https://github.com/btoneill/foreman_fog_proxmox/issues/335)) ([595fa60](https://github.com/btoneill/foreman_fog_proxmox/commit/595fa60c04654571a2cacfb894440c63a61df45a))
* update volume [#115](https://github.com/btoneill/foreman_fog_proxmox/issues/115) ([e4c81a4](https://github.com/btoneill/foreman_fog_proxmox/commit/e4c81a464248fb592f336c5bfaf99ff09dee383a))
* VLAN Tag is not transmitted to the proxmox api at vm creation ([4e22c5b](https://github.com/btoneill/foreman_fog_proxmox/commit/4e22c5b9e761aeb63707c184645b13fa0f7826c6)), closes [#228](https://github.com/btoneill/foreman_fog_proxmox/issues/228)
* volume device number [#78](https://github.com/btoneill/foreman_fog_proxmox/issues/78) ([cff4c4e](https://github.com/btoneill/foreman_fog_proxmox/commit/cff4c4e8fd812cdd12da76252fc154f1e0d602bc))
* volume server create controller device ([74b4af7](https://github.com/btoneill/foreman_fog_proxmox/commit/74b4af755fa3907e914c79bb403c1f5c246eaa31))


### Miscellaneous Chores

* release 0.16.2 ([#354](https://github.com/btoneill/foreman_fog_proxmox/issues/354)) ([1f44d6f](https://github.com/btoneill/foreman_fog_proxmox/commit/1f44d6f92ed330f500f39db32c9cee4f96eb04f0))
>>>>>>> 0881825 (chore(master): release 0.16.2)

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
