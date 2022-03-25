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

Note that this will save an InfluxDB administrative token to the user's home directory, typically `/root/.influxdb_token`.  The `puppetlabs/influxdb` types and providers can make use of this file during catalog application.  The manifests in this module are also able to use it via [deferred functions](https://puppet.com/docs/puppet/7/deferring_functions.html), which also run on the agent as the first step of catalog application.  Therefore, it is possible to use this file for all token-based operations in this module, and no further configuration is required.

It is also possible to specify this token via the `influxdb::token` parameter in hiera.  The Telegraf token used by the `telegraf` service and Grafana datasource can also be set via `puppet_operational_dashboards::telegraf_token`.  These are both `Sensitive` strings, so the recommended way to use them is to encrypt them with [hiera-eyaml](https://github.com/voxpupuli/hiera-eyaml) and use the encrypted value in hiera data.  After setting up a hierarchy to use the [eyaml backend](https://github.com/voxpupuli/hiera-eyaml#with-hiera-5), the values can be added to hiera data and automatically converted to `Sensitive`:

```
influxdb::token: <eyaml_encrypted_string>
lookup_options:
   influxdb::token:
     convert_to: "Sensitive"
```

These parameters take precedence over the file on disk if both are specified.


## Usage

### Evaluation order

When using the default configuration options and the deferred function to retreive the Telegraf token, note that it will not be available during the initial Puppet agent run that creates all of the resources.  A second run is required to retrieve the token and update the resources that use it.  If you are seeing authentication errors from Telegraf and Grafana, make sure the Puppet agent has been run twice and that the token has made its way to the Telegraf service config file:

```
/etc/systemd/system/telegraf.service.d/override.conf
```

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
