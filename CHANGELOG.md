# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v2.7.0](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v2.7.0) (2022-02-24)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/v2.6.1...v2.7.0)

### Added

- Allow ssl\_dir to be configured via Hiera [\#205](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/205) ([Sharpie](https://github.com/Sharpie))
- Enable PuppetDB SSL in dbcompiler profile [\#203](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/203) ([Sharpie](https://github.com/Sharpie))

### Fixed

- Accept 503 responses from PE /status APIs [\#204](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/204) ([Sharpie](https://github.com/Sharpie))

## [v2.6.1](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v2.6.1) (2021-11-04)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/v2.6.0...v2.6.1)

### Fixed

- \(SUP-2779\) Fix the bug - telegraf postgres metrics unable to obtain data [\#200](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/200) ([henrywangpuppet](https://github.com/henrywangpuppet))

## [v2.6.0](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v2.6.0) (2021-11-01)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/v2.5.0...v2.6.0)

### Added

- \(SUP-2769\) Bump default Grafana version from 5.1.4 to 8.2.2 [\#197](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/197) ([suckatrash](https://github.com/suckatrash))
- \(Sup-2754\) Adding SLES support [\#194](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/194) ([m0dular](https://github.com/m0dular))
- \(SUP-2194\) To add datasource variable for Archive Dashboards - PR 185 Replacement [\#192](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/192) ([henrywangpuppet](https://github.com/henrywangpuppet))
- Added repo\_gpgcheck and single quotes to influxdb [\#189](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/189) ([di2ejenkins](https://github.com/di2ejenkins))
- \(SUP-2137\) To add parameters to configure telegraf database retention policy [\#188](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/188) ([henrywangpuppet](https://github.com/henrywangpuppet))
- \(GH-158\) Add support for puppet-telegraf 4.1+ [\#166](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/166) ([jarretlavallee](https://github.com/jarretlavallee))
- \(\#151\) Install toml gem by default. [\#154](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/154) ([coreymbe](https://github.com/coreymbe))

### Fixed

- \(SUP-2732\) Fix PDB data tagged onto dashboard server issue and templa… [\#191](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/191) ([henrywangpuppet](https://github.com/henrywangpuppet))
- \(GH-172\) Add cgroup mapping for viewer [\#173](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/173) ([jarretlavallee](https://github.com/jarretlavallee))

## [v2.5.0](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v2.5.0) (2021-05-27)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/v2.4.0...v2.5.0)

### Added

- Enable remote PuppetDB collection in 2019.8.5+ [\#139](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/139) ([jarretlavallee](https://github.com/jarretlavallee))
- \(SUP-2195\) Add Archive Postgres Performance dashboard [\#128](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/128) ([Sharpie](https://github.com/Sharpie))
- Enable LDAP authentication for Grafana [\#108](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/108) ([coreymbe](https://github.com/coreymbe))

### Fixed

- Remove slash from dashboard name [\#132](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/132) ([timidri](https://github.com/timidri))
- change to http when client cert is false [\#131](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/131) ([WBasson](https://github.com/WBasson))
- Expose manage\_repo in dbcompiler::install class [\#129](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/129) ([suckatrash](https://github.com/suckatrash))

## [v2.4.0](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v2.4.0) (2020-12-30)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/v2.3.1...v2.4.0)

### Added

- \(SUP-2007\) Add local import and viewing of metrics [\#120](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/120) ([jarretlavallee](https://github.com/jarretlavallee))
- Improve multiserver telegraf dashboard support [\#114](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/114) ([seanmil](https://github.com/seanmil))
- Add tidy\_telegraf\_configs option on dbcompiler profile [\#112](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/112) ([seanmil](https://github.com/seanmil))
- Use supplied compiler name in dbcompiler [\#111](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/111) ([seanmil](https://github.com/seanmil))
- Support multiple Postgres instances [\#110](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/110) ([seanmil](https://github.com/seanmil))

### Fixed

- re-Add dashboard for JRuby per-borrow metrics [\#124](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/124) ([suckatrash](https://github.com/suckatrash))
- Detect new cert\_allowlist\_entry class [\#119](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/119) ([kreeuwijk](https://github.com/kreeuwijk))
- Fix raw queries in Postgres dashboard [\#117](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/117) ([seanmil](https://github.com/seanmil))
- Fix logic to select the v2 PuppetDB dashboards [\#113](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/113) ([seanmil](https://github.com/seanmil))

## [v2.3.1](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v2.3.1) (2020-08-11)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/v2.3.0...v2.3.1)

### Added

- Add dashboard for JRuby per-borrow metrics [\#106](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/106) ([suckatrash](https://github.com/suckatrash))
- Replace httpjson with http input [\#105](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/105) ([suckatrash](https://github.com/suckatrash))
- Make datasource for system metrics configurable [\#104](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/104) ([m0dular](https://github.com/m0dular))
- add description to InfluxDB yumrepo [\#98](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/98) ([vchepkov](https://github.com/vchepkov))
- PuppetDB on Compilers [\#97](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/97) ([coreymbe](https://github.com/coreymbe))
- Update PE PuppetDB metrics [\#95](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/95) ([Sharpie](https://github.com/Sharpie))

### Fixed

- Fix measurement names for Process dashboards [\#102](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/102) ([m0dular](https://github.com/m0dular))

### UNCATEGORIZED PRS; LABEL THEM ON GITHUB

- \(maint\) v2.3.1 release prep [\#103](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/103) ([suckatrash](https://github.com/suckatrash))

## [v2.3.0](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v2.3.0) (2020-04-15)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/v2.2.0...v2.3.0)

### Added

- Make the tidy resource optional [\#93](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/93) ([suckatrash](https://github.com/suckatrash))

### Fixed

- \(DIO-563\) addresses CVE-2020-7943 [\#92](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/92) ([suckatrash](https://github.com/suckatrash))

## [v2.2.0](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v2.2.0) (2020-03-20)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/v2.0.1...v2.2.0)

### Added

- \(SLV-788\) New and updated dashboards [\#89](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/89) ([RandellP](https://github.com/RandellP))
- OSP Compatibility Updates [\#87](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/87) ([jarretlavallee](https://github.com/jarretlavallee))
- Use the `puppetserver.jruby` metrics in the dashboard examples [\#79](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/79) ([jarretlavallee](https://github.com/jarretlavallee))
- Added arbitrary grafana config [\#76](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/76) ([dylanratcliffe](https://github.com/dylanratcliffe))
- Added ability to set default password [\#75](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/75) ([dylanratcliffe](https://github.com/dylanratcliffe))

### Fixed

- \(maint\) correct script name [\#90](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/90) ([tkishel](https://github.com/tkishel))
- Update certs.pp [\#73](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/73) ([uberjew666](https://github.com/uberjew666))

## [v2.0.1](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v2.0.1) (2019-07-11)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/v2.0.0...v2.0.1)

## [v2.0.0](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v2.0.0) (2019-07-11)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/v1.1.5...v2.0.0)

### Added

- Switching to in module hiera data & updating docs [\#65](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/65) ([genebean](https://github.com/genebean))
- Improve PuppetDB metric dashboards [\#63](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/63) ([Sharpie](https://github.com/Sharpie))
- Add profiles, move puppetdb metric defaults \(part 2\) [\#62](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/62) ([suckatrash](https://github.com/suckatrash))
- Select PuppetDB metrics based on version [\#56](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/56) ([seanmil](https://github.com/seanmil))
- Update dashboard templates [\#52](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/52) ([Sharpie](https://github.com/Sharpie))

### Fixed

- Fix archive dashboard query for compile time [\#64](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/64) ([Sharpie](https://github.com/Sharpie))
- Use certname consistently for key files [\#55](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/55) ([seanmil](https://github.com/seanmil))
- Ensure http timeout is set in all inputs.http\* for telegraf [\#54](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/54) ([jarretlavallee](https://github.com/jarretlavallee))

## [v1.1.5](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/v1.1.5) (2019-04-25)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/1.1.0...v1.1.5)

### Added

- Allow port numbers of services to be specified [\#50](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/50) ([Sharpie](https://github.com/Sharpie))
- Improve support for FOSS puppet dashboards [\#49](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/49) ([suckatrash](https://github.com/suckatrash))
- add puppetdb heap / status [\#39](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/39) ([suckatrash](https://github.com/suckatrash))
- add a metric for last successful file-sync commit [\#36](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/36) ([suckatrash](https://github.com/suckatrash))

### Fixed

- Stop creating /run/grafana on CentOS 7 [\#38](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/38) ([Sharpie](https://github.com/Sharpie))

## [1.1.0](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/1.1.0) (2019-02-13)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/1.0.3...1.1.0)

### Added

- Add postgresql metrics collection [\#30](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/30) ([suckatrash](https://github.com/suckatrash))
- Add params, separate configs [\#20](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/20) ([genebean](https://github.com/genebean))

## [1.0.3](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/1.0.3) (2018-12-01)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/1.0.2...1.0.3)

### Fixed

- Removed unless block from template [\#11](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/11) ([genebean](https://github.com/genebean))

## [1.0.2](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/1.0.2) (2018-08-06)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/1.0.1...1.0.2)

### Fixed

- \(maint\) add license file [\#8](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/8) ([suckatrash](https://github.com/suckatrash))

## [1.0.1](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/1.0.1) (2018-07-06)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/1.0.0...1.0.1)

### Added

- Merging up everything currently in development [\#4](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/4) ([suckatrash](https://github.com/suckatrash))

### Fixed

- \(GH12\) Update systemd tmpfiles [\#3](https://github.com/puppetlabs/puppet_metrics_dashboard/pull/3) ([jarretlavallee](https://github.com/jarretlavallee))

## [1.0.0](https://github.com/puppetlabs/puppet_metrics_dashboard/tree/1.0.0) (2018-07-02)

[Full Changelog](https://github.com/puppetlabs/puppet_metrics_dashboard/compare/f3f1e9fcc37b55ac53619e2c47baa2cf0eeab838...1.0.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
