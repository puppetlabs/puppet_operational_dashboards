# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v1.7.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.7.0) (2022-10-18)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.6.0...v1.7.0)

### Added

- Accept a support script tarball for archive metrics ingest [\#96](https://github.com/puppetlabs/puppet_operational_dashboards/pull/96) ([m0dular](https://github.com/m0dular))

## [v1.6.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.6.0) (2022-10-12)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.5.0...v1.6.0)

### Added

- Add file sync client metrics to archive script [\#91](https://github.com/puppetlabs/puppet_operational_dashboards/pull/91) ([m0dular](https://github.com/m0dular))
- \(SUP-3688\) Plans to provision and import metrics [\#87](https://github.com/puppetlabs/puppet_operational_dashboards/pull/87) ([m0dular](https://github.com/m0dular))
- \(SUP-3565\) Support Telegraf archive install on EL [\#75](https://github.com/puppetlabs/puppet_operational_dashboards/pull/75) ([m0dular](https://github.com/m0dular))

### Fixed

- Check type of $targets parameter [\#92](https://github.com/puppetlabs/puppet_operational_dashboards/pull/92) ([m0dular](https://github.com/m0dular))

## [v1.5.0](https://github.com/puppetlabs/puppet_operational_dashboards/tree/v1.5.0) (2022-10-11)

[Full Changelog](https://github.com/puppetlabs/puppet_operational_dashboards/compare/v1.4.0...v1.5.0)

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
