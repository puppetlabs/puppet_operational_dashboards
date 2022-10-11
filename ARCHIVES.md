# Batch import of puppet_metrics_collector archives

## Requirements

This module offers Bolt plans to provision a non-SSL dashboard node and to import archive metrics.  You will need a [Bolt installation](https://puppet.com/docs/bolt/latest/bolt_installing.html) on a client node and access to the remote node you wish to target.

## Setup

* Install Bolt and clone this module
```
git clone https://github.com/puppetlabs/puppet_operational_dashboards.git
```
* Install the required modules
```
cd puppet_operational_dashboards
bolt module install
```
* Install the toml-rb gem
```
/opt/puppetlabs/bolt/bin/gem install --user-install toml-rb
```

## Usage

### puppet_operational_dashboards::provision_dashboard
```
  bolt plan run puppet_operational_dashboards::provision_dashboard targets=<value>

Parameters
  targets  TargetSpec
    The targets to run on.
```

### puppet_operational_dashboards::load_metrics

The only mandatory parameter is `metrics_dir`, the path to the metrics contained in a PE support script.
```
  bolt plan run puppet_operational_dashboards::load_metrics
  [cleanup_metrics=<value>] [conf_dir=<value>] [dest_dir=<value>]
  [grafana_datasource=<value>] [influxdb_bucket=<value>] [influxdb_org=<value>]
  [influxdb_port=<value>] metrics_dir=<value> targets=<value>
  [telegraf_process=<value>] [telegraf_token=<value>] [token=<value>]
  [token_file=<value>]

Parameters
  cleanup_metrics  String
    Whether to delete metrics after processing
    Default: 'true'

  conf_dir  String
    Directory to upload Telegraf configuration files to
    Default: '/tmp/telegraf'

  dest_dir  String
    Directory to upload $metrics_dir to
    Default: '/tmp'

  grafana_datasource  String
    Name of the Grafana datasource.  Must match the name of the InfluxDB bucket
    Default: $influxdb_bucket

  influxdb_bucket  String
    Name of the InfluxDB bucket to configure and query. Defaults to 'puppet_data'
    Default: 'puppet_data'

  influxdb_org  String
    Name of the InfluxDB organization to configure. Defaults to 'puppetlabs'
    Default: 'puppetlabs'

  influxdb_port  Integer
    Port used by the InfluxDB service.  Defaults to the value of influxdb::port, or
    8086 if unset
    Default: 8086

  metrics_dir  String
    Path to the 'metrics' directory from a PE support script

  targets  TargetSpec
    The targets to run on.

  telegraf_process  Enum['local', 'remote']
    Default: 'remote'

  telegraf_token  String
    Name of the token to retrieve from InfluxDB. Defaults to 'puppet telegraf token'
    Default: 'puppet telegraf token'

  token  Optional[String]
    Default: undef

  token_file  String
    Location on disk of an InfluxDB admin token.
    This file is written to by the influxdb class during installation and read by
    the type and providers,
    as well Deferred functions in this module.
    Default: '/root/.influxdb_token'
```
