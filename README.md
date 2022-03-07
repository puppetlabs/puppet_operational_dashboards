# puppet_operational_dashboards

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with puppet_operational_dashboards](#setup)
    * [Beginning with puppet_operational_dashboards](#beginning-with-puppet_operational_dashboards)
1. [Usage - Configuration options and additional functionality](#usage)
    * [Determining where Telegraf runs](#determining-where-telegraf-runs)

## Description

This module is a replacement for the [puppet_metrics_dashboard module](https://forge.puppet.com/modules/puppetlabs/puppet_metrics_dashboard).  It is used to configure Telegraf, InfluxDB, and Grafana to collect, store, and display metrics collected from Puppet services. By default, those components are installed on a separate Dashboard node by applying the base class of this module to that node. That class will automatically query PuppetDB for Puppet Infrastructure nodes (Primary server, Compilers, PuppetDB hosts, PostgreSQL hosts) or you can specify them via associated class parameters. It is not recommended to apply the base class of this module to one of your Puppet Infrastructure nodes.


## Setup

### Prerequisites

The toml-rb gem needs to be installed in the Puppetserver gem space, which can be done with the [influxdb::profile::toml](https://github.com/puppetlabs/influxdb/blob/main/manifests/profile/toml.pp) class in the InfluxDB module.

To collect PostgreSQL metrics, classify your PostgreSQL nodes with the [puppet_operational_dashboards::profile::postgres_access](https://github.com/puppetlabs/puppet_operational_dashboards/blob/main/manifests/profile/postgres_access.pp) class.  FOSS users will need to manually configure the PostgreSQL authentication settings.

### Beginning with puppet_operational_dashboards

The easiest way to get started using this module is by including the `puppet_operational_dashboards` class to install and configure Telegraf, InfluxDB, and Grafana.  Note that you also need to install the toml-rb gem according to the [prerequisites](#setup-prerequisites).

```
include puppet_operational_dashboards
```

Doing so will:

* Install and configure InfluxDB using the [puppetlabs/influxdb module](https://forge.puppet.com/modules/puppetlabs/influxdb#what-influxdb-affects)
* Install and configure Telegraf to collect metrics from your PE infrastructure.  FOSS users can specify a list of infrastructure nodes via the `puppet_operational_dashboards::telegraf::agent` parameters.
* Install and configure Grafana with several dashboards to display data from InfluxDB


## Usage

### Determining where Telegraf runs

Which hosts a node collects metrics from is determined by the `puppet_operational_dashboards::telegraf::agent::collection_method` parameter.  By default, the `puppet_operational_dashboards` class will collect metrics from all nodes in a PE infrastructure.  If you want to change this behavior, set `collection_method` to `local` or `none`.  Telegraf can be run on other nodes by applying the `puppet_operational_dashboards::telegraf::agent` class to them, for example:

```
class {'puppet_operational_dashboards::telegraf::agent':
  collection_method => 'local',
  token => <my_sensitive_token>,
}
```

### Importing archive metrics

Metrics archives output by the [Puppet metrics collector](https://forge.puppet.com/modules/puppetlabs/puppet_metrics_collector) can be imported into InfluxDB using the scripts in the `examples/` directory.  The sample `bucket_and_datasource` class shows how to configure an InfluxDB bucket and Grafana datasource, while the Telegraf files can be used to load the data into the bucket.  After setting up the bucket and datasource:

* Download the `telegraf.conf` and `telegraf.conf.d` files to your home directory.
* Extract the archive
```
tar xf <metrics_gz>
cd <output_directory>
```
* Delete any Puppet server metrics with errors.

Currently, these will cause the `telegraf` process to exit upon encountering an error.  Delete these with:
```
find <puppet_server_metrics_dir> -type f -name "*json" -size -1000c -delete
```
* Edit `telegraf.conf` to point to your bucket (`<my_bucket>`) and InfluxDB server (`<influxdb_fqdn>`).
* Export your Telegraf token
```
export INFLUX_TOKEN=<token>
```
This token can be found in the "API Tokens" tab of the "Data" page in InfluxDB
* Run Telegraf to import the metrics.  This can be done all at once:
```
telegraf --once --debug --config ~/telegraf.conf --config-directory ~/telegraf.conf.d/
```

Or one service at a time, e.g. for Puppet server
```
telegraf --once --debug --config ~/telegraf.conf --config ~/telegraf.conf.d//puppetserver.conf
```
