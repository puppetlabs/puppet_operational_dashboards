# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v2.1.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v2.1.0) (2023-09-25)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v2.0.0...v2.1.0)

### Added

- \(SUP-3616\) Support HTTPS Grafana connections [\#189](https://github.com/puppetlabs/puppet_operational_dashboards/pull/189) ([m0dular](https://github.com/m0dular))
- README.md: Document more hiera examples [\#186](https://github.com/puppetlabs/puppet_operational_dashboards/pull/186) ([bastelfreak](https://github.com/bastelfreak))
- Bump module dependencies [\#185](https://github.com/puppetlabs/puppet_operational_dashboards/pull/185) ([m0dular](https://github.com/m0dular))
- \(SUP-4332\) Add lag\_bytes to postgres dashboard [\#184](https://github.com/puppetlabs/puppet_operational_dashboards/pull/184) ([m0dular](https://github.com/m0dular))
- Grafana: Update 8.5.20-\>8.5.26 [\#183](https://github.com/puppetlabs/puppet_operational_dashboards/pull/183) ([bastelfreak](https://github.com/bastelfreak))
- puppet/telegraf: Require 5.x; puppetlabs/stdib: Require 9.x  [\#181](https://github.com/puppetlabs/puppet_operational_dashboards/pull/181) ([bastelfreak](https://github.com/bastelfreak))
- telegraf: Bump 1.25.3-1-\>1.27.0-1 [\#180](https://github.com/puppetlabs/puppet_operational_dashboards/pull/180) ([bastelfreak](https://github.com/bastelfreak))
- Add state timelines for catalog and function perf [\#177](https://github.com/puppetlabs/puppet_operational_dashboards/pull/177) ([m0dular](https://github.com/m0dular))

### Fixed

- \(SUP-4436\) Grafana Module Version Change [\#190](https://github.com/puppetlabs/puppet_operational_dashboards/pull/190) ([Aaronoftheages](https://github.com/Aaronoftheages))
- \(GH-187\) Update grafana\_wait.epp template to use grafana\_port value [\#188](https://github.com/puppetlabs/puppet_operational_dashboards/pull/188) ([rjd1](https://github.com/rjd1))
- \(\#74\) collect local PCP metrics [\#179](https://github.com/puppetlabs/puppet_operational_dashboards/pull/179) ([bastelfreak](https://github.com/bastelfreak))
- \(\#74\) Fix include\_pe\_metrics in telegraf class [\#178](https://github.com/puppetlabs/puppet_operational_dashboards/pull/178) ([bastelfreak](https://github.com/bastelfreak))

## [v2.0.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v2.0.0) (2023-05-26)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.13.1...v2.0.0)

### Added

- Import sar data files [\#172](https://github.com/puppetlabs/puppet_operational_dashboards/pull/172) ([m0dular](https://github.com/m0dular))
- \(SUP-4220\) Add panels for PDB pool usage [\#171](https://github.com/puppetlabs/puppet_operational_dashboards/pull/171) ([m0dular](https://github.com/m0dular))
- \(SUP-4138\) Add compiler PCP metrics [\#168](https://github.com/puppetlabs/puppet_operational_dashboards/pull/168) ([m0dular](https://github.com/m0dular))
- \(SUP-4138\) Add PCP connections [\#167](https://github.com/puppetlabs/puppet_operational_dashboards/pull/167) ([m0dular](https://github.com/m0dular))
- Add dashboard and script for v2 system metrics [\#166](https://github.com/puppetlabs/puppet_operational_dashboards/pull/166) ([m0dular](https://github.com/m0dular))
- Document parameters for internal repositories [\#165](https://github.com/puppetlabs/puppet_operational_dashboards/pull/165) ([m0dular](https://github.com/m0dular))

### Fixed

- Remove selection override from db sizes panel [\#173](https://github.com/puppetlabs/puppet_operational_dashboards/pull/173) ([m0dular](https://github.com/m0dular))

## [v1.13.1](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.13.1) (2023-04-27)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.13.0...v1.13.1)

### Changed

- \(SUP-3952\) Remove Puppet 6 as a supported platform [\#158](https://github.com/puppetlabs/puppet_operational_dashboards/pull/158) ([elainemccloskey](https://github.com/elainemccloskey))

### Added

- Allow differentiation between ssl influxdb and puppet ssl connections [\#161](https://github.com/puppetlabs/puppet_operational_dashboards/pull/161) ([tuxmea](https://github.com/tuxmea))
- \(SUP-4194\) Puppet 8 release prep [\#159](https://github.com/puppetlabs/puppet_operational_dashboards/pull/159) ([elainemccloskey](https://github.com/elainemccloskey))
- Allow disabling of System Performance dashboard creation [\#157](https://github.com/puppetlabs/puppet_operational_dashboards/pull/157) ([tuxmea](https://github.com/tuxmea))
- telegraf: Update 1.24.3-1-\>1.25.3-1 [\#155](https://github.com/puppetlabs/puppet_operational_dashboards/pull/155) ([bastelfreak](https://github.com/bastelfreak))

### Fixed

- Restore missing operational\_dashboards tag [\#154](https://github.com/puppetlabs/puppet_operational_dashboards/pull/154) ([m0dular](https://github.com/m0dular))

## [v1.13.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.13.0) (2023-03-29)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.12.0...v1.13.0)

### Fixed

- pe\_profiles\_on\_host: Fix orchestrator support [\#151](https://github.com/puppetlabs/puppet_operational_dashboards/pull/151) ([bastelfreak](https://github.com/bastelfreak))

## [v1.12.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.12.0) (2023-03-27)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.11.0...v1.12.0)

### Added

- \(SUP-4087\) Add Orchestrator metrics [\#148](https://github.com/puppetlabs/puppet_operational_dashboards/pull/148) ([m0dular](https://github.com/m0dular))
- \(SUP-4065\) Add parameter for group\_by interval [\#146](https://github.com/puppetlabs/puppet_operational_dashboards/pull/146) ([m0dular](https://github.com/m0dular))

### Fixed

- Fix null checks in puppetserver import script [\#149](https://github.com/puppetlabs/puppet_operational_dashboards/pull/149) ([m0dular](https://github.com/m0dular))
- limit apt workaround scope to Debian [\#145](https://github.com/puppetlabs/puppet_operational_dashboards/pull/145) ([vchepkov](https://github.com/vchepkov))

## [v1.11.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.11.0) (2023-02-28)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.10.0...v1.11.0)

### Added

- Add influxdb\_bucket\_retention\_rules parameter [\#141](https://github.com/puppetlabs/puppet_operational_dashboards/pull/141) ([SimonHoenscheid](https://github.com/SimonHoenscheid))
- update grafana\_version to fix CVE-2022-23552 and CVE-2022-39324 [\#138](https://github.com/puppetlabs/puppet_operational_dashboards/pull/138) ([SimonHoenscheid](https://github.com/SimonHoenscheid))

### Fixed

- Group the total db size by 5m intervals [\#139](https://github.com/puppetlabs/puppet_operational_dashboards/pull/139) ([m0dular](https://github.com/m0dular))
- Fix JRuby lock wait and held times [\#137](https://github.com/puppetlabs/puppet_operational_dashboards/pull/137) ([m0dular](https://github.com/m0dular))

## [v1.10.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.10.0) (2023-02-07)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.9.0...v1.10.0)

### Added

- Update default version of grafana installed [\#132](https://github.com/puppetlabs/puppet_operational_dashboards/pull/132) ([elainemccloskey](https://github.com/elainemccloskey))
- \(SUP-3459\) Add queries for G1GC metrics [\#124](https://github.com/puppetlabs/puppet_operational_dashboards/pull/124) ([m0dular](https://github.com/m0dular))
- Pass port to InfluxDB resources [\#118](https://github.com/puppetlabs/puppet_operational_dashboards/pull/118) ([m0dular](https://github.com/m0dular))

### Fixed

- Filesync dashboard cleanup [\#123](https://github.com/puppetlabs/puppet_operational_dashboards/pull/123) ([seanmil](https://github.com/seanmil))
- Ensure consistent config generation order [\#122](https://github.com/puppetlabs/puppet_operational_dashboards/pull/122) ([seanmil](https://github.com/seanmil))

## [v1.9.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.9.0) (2022-12-02)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.8.0...v1.9.0)

### Added

- timeouts for http inputs are now configurable [\#114](https://github.com/puppetlabs/puppet_operational_dashboards/pull/114) ([SimonHoenscheid](https://github.com/SimonHoenscheid))

## [v1.8.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.8.0) (2022-11-07)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.7.0...v1.8.0)

### Added

- \(SUP-3761\) Add thread and file descriptor panels [\#106](https://github.com/puppetlabs/puppet_operational_dashboards/pull/106) ([m0dular](https://github.com/m0dular))
- \(SUP-3735\) have dashboards autorefresh [\#103](https://github.com/puppetlabs/puppet_operational_dashboards/pull/103) ([MartyEwings](https://github.com/MartyEwings))
- mv telegraf agent os-specific params to hiera data [\#101](https://github.com/puppetlabs/puppet_operational_dashboards/pull/101) ([zoojar](https://github.com/zoojar))
- added insecure\_skip\_verify param [\#100](https://github.com/puppetlabs/puppet_operational_dashboards/pull/100) ([zoojar](https://github.com/zoojar))

### Fixed

- \(SUP-3764\) Fix compatability with Telegraf 1.24.3 [\#109](https://github.com/puppetlabs/puppet_operational_dashboards/pull/109) ([m0dular](https://github.com/m0dular))

## [v1.7.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.7.0) (2022-10-18)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.6.0...v1.7.0)

### Added

- Accept a support script tarball for archive metrics ingest [\#96](https://github.com/puppetlabs/puppet_operational_dashboards/pull/96) ([m0dular](https://github.com/m0dular))

## [v1.6.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.6.0) (2022-10-12)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.5.0...v1.6.0)

### Added

- Add file sync client metrics to archive script [\#91](https://github.com/puppetlabs/puppet_operational_dashboards/pull/91) ([m0dular](https://github.com/m0dular))

### Fixed

- Check type of $targets parameter [\#92](https://github.com/puppetlabs/puppet_operational_dashboards/pull/92) ([m0dular](https://github.com/m0dular))

## [v1.5.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.5.0) (2022-10-11)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.4.0...v1.5.0)

### Added

- \(SUP-3688\) Plans to provision and import metrics [\#87](https://github.com/puppetlabs/puppet_operational_dashboards/pull/87) ([m0dular](https://github.com/m0dular))
- \(SUP-3565\) Support Telegraf archive install on EL [\#75](https://github.com/puppetlabs/puppet_operational_dashboards/pull/75) ([m0dular](https://github.com/m0dular))

## [v1.4.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.4.0) (2022-09-30)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.3.0...v1.4.0)

### Added

- \(SUP-3675\) Remove -H flag from ss command [\#86](https://github.com/puppetlabs/puppet_operational_dashboards/pull/86) ([m0dular](https://github.com/m0dular))
- Pass use\_ssl param to InfluxDB resources [\#84](https://github.com/puppetlabs/puppet_operational_dashboards/pull/84) ([m0dular](https://github.com/m0dular))

## [v1.3.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.3.0) (2022-09-19)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.2.0...v1.3.0)

### Added

- \(SUP-3646\) Grafana Bump for security vulnerability [\#79](https://github.com/puppetlabs/puppet_operational_dashboards/pull/79) ([MartyEwings](https://github.com/MartyEwings))
- SUP-3276 Add system metrics from archives [\#71](https://github.com/puppetlabs/puppet_operational_dashboards/pull/71) ([m0dular](https://github.com/m0dular))
- \(SUP-3431\) Add index and toast stats to postgres [\#70](https://github.com/puppetlabs/puppet_operational_dashboards/pull/70) ([m0dular](https://github.com/m0dular))
- \(SUP-3220\) Rewrite Puppet server script [\#68](https://github.com/puppetlabs/puppet_operational_dashboards/pull/68) ([m0dular](https://github.com/m0dular))

### Fixed

- README.md: Cleanup trailing whitespace  / Fix typo [\#73](https://github.com/puppetlabs/puppet_operational_dashboards/pull/73) ([bastelfreak](https://github.com/bastelfreak))
- \(SUP-3396\) Remove ha\_last-sync-succeeded mbeans [\#72](https://github.com/puppetlabs/puppet_operational_dashboards/pull/72) ([m0dular](https://github.com/m0dular))
- \(SUP-3388\) Change error handling in PDB script [\#69](https://github.com/puppetlabs/puppet_operational_dashboards/pull/69) ([m0dular](https://github.com/m0dular))
- \(SUP-3403\) Fix labels in compile/borrow panel [\#67](https://github.com/puppetlabs/puppet_operational_dashboards/pull/67) ([m0dular](https://github.com/m0dular))

## [v1.2.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.2.0) (2022-06-10)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.1.0...v1.2.0)

### Added

- \(SUP-3025\) Add spec tests [\#63](https://github.com/puppetlabs/puppet_operational_dashboards/pull/63) ([m0dular](https://github.com/m0dular))

### Fixed

- \(SUP-3358\) Fix $use\_ssl logic across all manifests [\#62](https://github.com/puppetlabs/puppet_operational_dashboards/pull/62) ([m0dular](https://github.com/m0dular))
- \(SUP-3357\) Move manage\_grafana to dashboard class [\#61](https://github.com/puppetlabs/puppet_operational_dashboards/pull/61) ([m0dular](https://github.com/m0dular))
- \(SUP-3348\) Telegraf ssl bugfixes [\#60](https://github.com/puppetlabs/puppet_operational_dashboards/pull/60) ([m0dular](https://github.com/m0dular))

## [v1.1.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.1.0) (2022-05-27)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.0.0...v1.1.0)

### Added

- \(SUP-3329\) Add metric archive info to ARCHIVES.md [\#55](https://github.com/puppetlabs/puppet_operational_dashboards/pull/55) ([m0dular](https://github.com/m0dular))
- Add metrics from route-ids [\#53](https://github.com/puppetlabs/puppet_operational_dashboards/pull/53) ([m0dular](https://github.com/m0dular))
- Add PDB JVM GC panels [\#51](https://github.com/puppetlabs/puppet_operational_dashboards/pull/51) ([m0dular](https://github.com/m0dular))
- Add panels for Puppet server GC times and counts [\#50](https://github.com/puppetlabs/puppet_operational_dashboards/pull/50) ([m0dular](https://github.com/m0dular))
- \(SUP-3250\) Add HA and other PDB panels [\#48](https://github.com/puppetlabs/puppet_operational_dashboards/pull/48) ([m0dular](https://github.com/m0dular))

### Fixed

- \(SUP-3319\) Refresh service when datasource changes [\#54](https://github.com/puppetlabs/puppet_operational_dashboards/pull/54) ([m0dular](https://github.com/m0dular))
- Fix queue\_depth metric in starlark processor [\#49](https://github.com/puppetlabs/puppet_operational_dashboards/pull/49) ([m0dular](https://github.com/m0dular))
- Fix panels related to PDB connections [\#47](https://github.com/puppetlabs/puppet_operational_dashboards/pull/47) ([m0dular](https://github.com/m0dular))

## [v1.0.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.0.0) (2022-05-04)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v0.2.0...v1.0.0)

### Changed

- \(SUP-3061\) Install class for ent infrastructure agents [\#36](https://github.com/puppetlabs/puppet_operational_dashboards/pull/36) ([MartyEwings](https://github.com/MartyEwings))

### Added

- Display all http client and function metrics [\#43](https://github.com/puppetlabs/puppet_operational_dashboards/pull/43) ([m0dular](https://github.com/m0dular))
- Add panels for PDB read and write pools [\#42](https://github.com/puppetlabs/puppet_operational_dashboards/pull/42) ([m0dular](https://github.com/m0dular))
- \(SUP-3243\) Add index stats for pe-puppetdb tables [\#40](https://github.com/puppetlabs/puppet_operational_dashboards/pull/40) ([m0dular](https://github.com/m0dular))
- \(SUP-3241\) Add in Dashboard documentation [\#39](https://github.com/puppetlabs/puppet_operational_dashboards/pull/39) ([MartyEwings](https://github.com/MartyEwings))
- Check for existance of keys in dict [\#26](https://github.com/puppetlabs/puppet_operational_dashboards/pull/26) ([m0dular](https://github.com/m0dular))

### Fixed

- \(SUP-3235\) Use latest telegraf package on Ubuntu [\#38](https://github.com/puppetlabs/puppet_operational_dashboards/pull/38) ([m0dular](https://github.com/m0dular))
- make resource ordering specific to install class [\#37](https://github.com/puppetlabs/puppet_operational_dashboards/pull/37) ([MartyEwings](https://github.com/MartyEwings))
- \(SUP-3228\) Fix Ubuntu compatibility issue [\#35](https://github.com/puppetlabs/puppet_operational_dashboards/pull/35) ([MartyEwings](https://github.com/MartyEwings))
- \(SUP-3201\) Check port availability with systemd [\#33](https://github.com/puppetlabs/puppet_operational_dashboards/pull/33) ([m0dular](https://github.com/m0dular))
- \(SUP-3201\) Accept any Sensitive value in template [\#32](https://github.com/puppetlabs/puppet_operational_dashboards/pull/32) ([m0dular](https://github.com/m0dular))
- \(SUP-3209\) Grant pg\_monitor role to telegraf [\#31](https://github.com/puppetlabs/puppet_operational_dashboards/pull/31) ([m0dular](https://github.com/m0dular))
- \(SUP-3201\) Make Grafana datasource idempotent [\#30](https://github.com/puppetlabs/puppet_operational_dashboards/pull/30) ([m0dular](https://github.com/m0dular))
- Fix handling of 'error' entry in dict [\#28](https://github.com/puppetlabs/puppet_operational_dashboards/pull/28) ([m0dular](https://github.com/m0dular))

## [v0.2.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v0.2.0) (2022-03-11)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v0.1.2...v0.2.0)

### Added

- Use retrieve\_token as a Deferred function [\#21](https://github.com/puppetlabs/puppet_operational_dashboards/pull/21) ([m0dular](https://github.com/m0dular))

### Fixed

- Fix postgres auth for Telegraf agents [\#19](https://github.com/puppetlabs/puppet_operational_dashboards/pull/19) ([m0dular](https://github.com/m0dular))

## [v0.1.2](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v0.1.2) (2022-03-08)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v0.1.1...v0.1.2)

### Fixed

- Fix name [\#14](https://github.com/puppetlabs/puppet_operational_dashboards/pull/14) ([m0dular](https://github.com/m0dular))

## [v0.1.1](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v0.1.1) (2022-03-08)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/d9a8f5e0fcdd1a64d95fec8a39eda863c0697e0e...v0.1.1)

### Fixed

- Add README [\#5](https://github.com/puppetlabs/puppet_operational_dashboards/pull/5) ([m0dular](https://github.com/m0dular))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
