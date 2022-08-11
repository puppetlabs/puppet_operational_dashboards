# puppet_operational_dashboards

## Table of Contents

- [puppet_operational_dashboards](#puppet_operational_dashboards)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Setup](#setup)
    - [Prerequisites](#prerequisites)
    - [Beginning with puppet_operational_dashboards](#beginning-with-puppet_operational_dashboards)
      - [Installing on Puppet Enterprise](#installing-on-puppet-enterprise)
      - [Installing on Puppet Open Source](#installing-on-puppet-open-source)
      - [What puppet_operational_dashboards affects](#what-puppet_operational_dashboards-affects)
  - [Usage](#usage)
    - [Evaluation order](#evaluation-order)
    - [Determining where Telegraf runs](#determining-where-telegraf-runs)
    - [Importing archive metrics](#importing-archive-metrics)
  - [Default Dashboards Available](#default-dashboards-available)
      - [Puppetserver Performance](#puppetserver-performance)
      - [Puppetserver Workload](#puppetserver-workload)
      - [File Sync Metrics](#file-sync-metrics)
      - [PuppetDB Performance](#puppetdb-performance)
      - [PuppetDB Workload](#puppetdb-workload)
      - [Postgres Metrics](#postgres-metrics)
  - [Limitations](#limitations)
  - [Troubleshooting](#troubleshooting)
## Description

This module is a replacement for the [puppet_metrics_dashboard module](https://forge.puppet.com/modules/puppetlabs/puppet_metrics_dashboard).  It is used to configure Telegraf, InfluxDB, and Grafana to collect, store, and display metrics collected from Puppet services. By default, those components are installed on a separate Dashboard node by applying the base class of this module to that node. That class will automatically query PuppetDB for Puppet Infrastructure nodes (Primary server, Compilers, PuppetDB hosts, PostgreSQL hosts) or you can specify them via associated class parameters. It is not recommended to apply the base class of this module to one of your Puppet Infrastructure nodes.


## Setup

### Prerequisites

### Beginning with puppet_operational_dashboards

#### Installing on Puppet Enterprise

To Install on Puppet Enterprise:

1. Classify `puppet_operational_dashboards::enterprise_infrastructure` to a node group that encompasses all Puppet Infrastructure agents. The default node group `PE Infrastructure Agent` is appropriate.

```
include puppet_operational_dashboards::enterprise_infrastructure
```

This will install the toml-rb gem on compiling nodes, and grant the appropriate access to the databases, for the dashboard node on all database nodes.

2. Classify `puppet_operational_dashboards` to the Puppet agent node to be designated as the Operational Dashboard node.

```
include puppet_operational_dashboards
```
This will install and configure Telegraf, InfluxDB, and Grafana.


Please note database access will not be granted until the Puppet agent run on the postgres nodes AFTER the application of `puppet_operational_dashboards` on the designated dashboard node.


#### Installing on Puppet Open Source

The toml-rb gem needs to be installed in the Puppetserver gem space, which can be done with the [influxdb::profile::toml](https://github.com/puppetlabs/influxdb/blob/main/manifests/profile/toml.pp) class in the InfluxDB module.

To collect PostgreSQL metrics, FOSS users will need to manually configure the PostgreSQL authentication settings.

The easiest way to get started using this module is by including the `puppet_operational_dashboards` class to install and configure Telegraf, InfluxDB, and Grafana.  Note that you also need to install the toml-rb gem according to the.

```
include puppet_operational_dashboards
```

#### What puppet_operational_dashboards affects
Installing the module will:

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

Metrics archives output by the [Puppet metrics collector](https://forge.puppet.com/modules/puppetlabs/puppet_metrics_collector) can be imported into InfluxDB using Telegraf and the scripts in the `examples/` directory.  See `ARCHIVES.md` for more.

## Default Dashboards Available
#### Puppetserver Performance
This dashboard is to inspect Puppet server performance and troubleshoot the `pe-puppetserver` service. Available panels:
- Puppetserver Performance
  This is a composite panel consisting of the following JRuby related metrics:
  - Average free JRubies
  - Average requested JRubies
  - Average JRuby borrow time
  - Average JRuby wait time
- Heap Memory and Uptime
  This panel displays the following JVM metrics:
  - Heap Committed
  - Heap Used
  - Uptime
- Average Requested JRubies
- Average Borrow/Compile Time
- Average Free JRubies
- Average Wait Time
- HTTP Client Metrics
  This panel displays the various network related metrics performed by Puppet server.  Examples include:
  - puppetdb.query.full_response
  - facts.find.full_response
- Borrow Timers Mean
  Average duration api requests require borrowing a JRuby from the pool
- Borrow Timers Rate
  Rate at which Puppet server performs the above api requests
- Function Timers
  Average duration of functions run as part of catalog compilations
- Function Timers Count
  Rate at which Puppet server performs the above api requests

**Use Case**
- Puppetserver service performance degraded
- 503 responses to agent requests
- Agent unable to get catalog
- Inspect performance for a particular type of request
- Inspect which type of request could be a performance bottleneck
#### File Sync Metrics
This dashboard is to inspect File-sync related performance. Available Graphs:
- Number of Fetch / Commits vs Lock wait / held
  - Average Lock Held Time
  - Avergee Lock Wait Time
  - Number of Commits
  - Number of Fetches
- File-Sync timing - Client Services
  - Average Clone Time
  - Average Fetch Time
  - Average Sync Time
  - Average Sync Clean Time
- File-Sync timing - Storage Services
  - Average Commit add / rm Time
  - Average Commit time
  - Average Clean Check time
  - Average Pre-commit Hook Time

**Use Case**
- Code Manager takes a significant time or fails to deploy code
- Puppetserver frequently locked due to file sync
- Compilers do not have the latest code available
#### PuppetDB Performance
This dashboard is to inspect PuppetDB performance and troubleshoot the `pe-puppetdb` service. Available panels:
- Heap
- Commands Per Second
- Command Processing Time
- Queue Depth
- Replace Catalog Time
- Replace Facts Time
- Store Report Time
- Average Read Duration
- Read Pool Pending Connections
- Average Write Duration
- Write Pool Pending Connections

**Use Case**
- Any PuppetDB performance issues
- Troubleshooting Read/Write Pool Errors

#### Postgres Performance
This dashboard is to inspect PostgreSQL database performance. Available panels:
- Temp Files
  Changes in temp file sizes per database over the given time interval
- Sizes by Database (total)
  Total size of each database, including tables, indexes, and toast
- Sizes by Table
  Size of each table, not including indexes or toast
- Sizes by Index
- Sizes by Toast
- Autovacuum Activity
- Vacuum Activity - (not auto, not full)
- I/O - heap toast and index - hits / reads
- Disk Block Reads (Heap)
  Changes in the number of disks blocks reads by postgres heap files per table.  This indicates the value needed to be retrieved from disk instead of the cache.
- Cache Reads (Heap)
  Changes in the number of cache reads by postgres heap files per table.  This indicates the value was retrieved from the cache.
- Disk Block Reads (Index)
  Same as above panel, but for indexes
- Cache Reads (Index)
  Same as above panel, but for indexes
- Disk Block Reads (Toast)
  Same as above panel, but for toast data
- Cache Reads (Toast)
  Same as above panel, but for toast data
- Live / Dead Tuples
- Deadlocks

**Use Cases**
- Monitor table sizes
- Monitor Deadlocks and Slow Queries
- Any PostgreSQL performance issues
### Limitations

## Ubuntu Telegraf Package
Currently, only the latest Telegraf package is provided by the Ubuntu repository.  Therefore, the only allowed value for `puppet_operational_dashboards::telegraf::agent::version` is `latest`.  Setting this parameter to a different value on Ubuntu will produce a warning.

## Upgrading from puppet_metrics_dashboard
This module uses InfluxDB 2.x, while `puppet_metrics_dashboard` uses 1.x.  This module does not currently provide an option to upgrade between these versions, so it is recommended to either install this module on a new node or manually upgrade.  See the [InfluxDB docs](https://docs.influxdata.com/influxdb/v2.2/upgrade/v1-to-v2/) for more information about upgrading.

## Applying classes on PE 2021.5 and 2021.6
On Puppet Enterprise versions 2021.5 and 2021.6, there is an issue when applying either the `puppet_operational_dashboards::enterprise_infrastructure` or `puppet_operational_dashboards::profile::postgres_access` classes in a user manifest.  Doing so may result in an error such as:

```
Error: Could not retrieve catalog from remote server: Error 500 on SERVER: Server Error: Evaluation Error: Error while evaluating a Resource Statement, Evaluation Error: Comparison of: Undef Value < Integer, is not possible. Caused by 'Only Strings, Numbers, Timespans, Timestamps, and Versions are comparable'
```

This is due to an ordering issue with the `cert_allowlist_entry` defined type.  The workaround is to apply the classes via the Console, for example by applying `puppet_operational_dashboards::enterprise_infrastructure` to the `PE Infrastructure Agent` node group.  See [Installing on Puppet Enterprise](#installing-on-puppet-enterprise).

This issue only affect PE versions 2021.5 and 2021.6.  Earlier versions are not affected, and later releases will include a fix to the defined type.

## Installing on openSUSE 15
On some versions of openSUSE 15, the `insserv-compat` package may be required to enable the Grafana service.  If you see an error such as:

```
Error: /Stage[main]/Grafana::Service/Service[grafana]/ensure: change from 'stopped' to 'running' failed: Could not enable grafana-server:
```

This is due to the missing package:

```
Synchronizing state of grafana-server.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable grafana-server
/sbin/insserv: No such file or directory
```

Installing the `insserv-compat` resolves the error.
### Troubleshooting
If data is not displaying in Grafana or you see errors in Telegraf collections, try checking the following items.

## Grafana datasource and time interval
A common reason for not seeing data in the dashboards is choosing the wrong datasource or time interval.  Double check that you have selected a datasource and window of time for which metrics have been collected.  Also, check that the `server` filter at the top of the dashboard contains valid entries.

Also, note that Telegraf performs its first collection after the first collection interval has passed.  You may need to wait for this to pass, or manually test using the method below.

Datasources can be tested via the "Data Sources" configuration page in Grafana.  Select the datasource, e.g. `influxdb_puppet`, and click the "Test" button.  Note that because this is a "provisioned datasource," it cannot be edited in the UI.

## Telegraf errors
A good way to test Telegraf collection is to use the `--test` option.  After logging into the node running `telegraf`, first export your token:
```
export INFLUX_TOKEN=<token>
```

The token can either be the admin token written to `/root/.influxdb_token` by default, or the `puppet telegraf token` used specifically for Telegraf.  See `REFERENCE.md` for more information.

Prepending a space before the `export` command will prevent the token from being written to you shell's history.

Then, test the collection:
```
telegraf --test --debug --config /etc/telegraf/telegraf.conf --config-directory /etc/telegraf/telegraf.d/
```

Services can also be tested individually, for example:

```
telegraf --test --debug --config /etc/telegraf/telegraf.conf --config /etc/telegraf/telegraf.d/puppetserver_metrics.conf
```

will only collect Puppet server metrics.
