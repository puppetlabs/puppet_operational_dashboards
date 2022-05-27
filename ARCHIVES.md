# Batch import of puppet_metrics_collector archives

## Requirements

Telegraf can be run manually to import archives from the `puppet_metrics_collector` module to InfluxDB.  To do so, you'll need the following:

* An InfluxDB [organization](https://github.com/puppetlabs/puppet_operational_dashboards/blob/main/REFERENCE.md#initial_org) and [bucket](https://github.com/puppetlabs/puppet_operational_dashboards/blob/main/REFERENCE.md#initial_bucket).  This module's defaults are `puppetlabs` and `puppet_data` respectively, but these can be configured via the linked parameters.

The sample [bucket_and_datasource class](https://github.com/puppetlabs/puppet_operational_dashboards/blob/main/examples/bucket_and_datasource.txt) shows how to create a bucket and Grafana datasource ad hoc using `puppet apply`.  See [#examples](#examples) for sample usage.

* A token with permissions to write to the bucket. This can be the admin token created by the [puppetlabs-influxdb module](https://github.com/puppetlabs/influxdb/blob/main/REFERENCE.md#token_file), or the [Telegraf token](https://github.com/puppetlabs/puppet_operational_dashboards/blob/main/REFERENCE.md#telegraf_token_name) created by this module.  For more information, see [what-puppet_operational_dashboards-affects](https://github.com/puppetlabs/puppet_operational_dashboards/blob/main/README.md#what-puppet_operational_dashboards-affects).

The token will need to be exported to the environment.  Prefacing this command with a space will keep it out of shell history:

```
export INFLUX_TOKEN=<token>
```

* A set of Telegraf configuration files and scripts to process and emit the metrics.

A sample [telegraf.conf](https://github.com/puppetlabs/puppet_operational_dashboards/tree/main/examples/telegraf.conf) to configure the application and [telegraf.conf.d](https://github.com/puppetlabs/puppet_operational_dashboards/tree/main/examples/telegraf.conf.d) directory to process the metrics are provided.

`telegraf.conf` will need to point to the bucket and url of your InfluxDB server.  Change `<my_bucket>` and `<influxdb_fqdn>` as needed.  See [examples](#examples) for sample usage.

* Valid SSL certs to talk to your InfluxDB server, if using SSL.

`puppetlabs-influxdb` defaults to configuring InfluxDB with SSL and uses certs issued by the Puppet CA.  In addition to configuring the InfluxDB application, it will copy the necessary certs to `/etc/telegraf` for Telegraf to communicate using SSL.  Therefore, if you are importing archive metrics on a node configured with the [puppet_operational_dashboards::telegraf::agent](https://github.com/puppetlabs/puppet_operational_dashboards/blob/main/REFERENCE.md#puppet_operational_dashboardstelegrafagent) class, this will already be in place.  If not, such as if you are importing archives from an unmanaged workstation, you will need the following:

An [SSL cert](https://github.com/puppetlabs/influxdb/blob/main/REFERENCE.md#ssl_cert_file) saved to `/etc/telegraf/cert.pem`.

A [CA cert](https://github.com/puppetlabs/influxdb/blob/main/REFERENCE.md#ssl_ca_file) saved to `/etc/telegraf/ca.pem`.


## Examples

These examples assume an organization named `puppetlabs`, a bucket named `puppet_data`, and an InfluxDB server with an fqdn of `influx-host`.

### Telegraf configuration

* Save [telegraf.conf](https://github.com/puppetlabs/puppet_operational_dashboards/tree/main/examples/telegraf.conf) to your home directory `~/telegraf.conf` and configure it:

```
[agent]
  hostname = ""
  omit_hostname = false
  interval = "10m"
  round_interval = true
  metric_batch_size = 10000
  metric_buffer_limit = 1000000
  collection_jitter = "0s"
  flush_interval = "5m"
  flush_jitter = "0s"
  precision = ""
  logfile = ""
  debug = false
  quiet = false

[[outputs.influxdb_v2]]
bucket = "puppet_data"
organization = "puppetlabs"
tls_ca = "/etc/telegraf/ca.pem"
tls_cert = "/etc/telegraf/cert.pem"
token = "$INFLUX_TOKEN"
urls = ["https://influx-host:8086"]
```

* Save the files in [telegraf.conf.d](https://github.com/puppetlabs/puppet_operational_dashboards/tree/main/examples/telegraf.conf.d) to your home directory `~/telegraf.conf.d`.  These don't require configuration unless the structure of your metrics files differs from the steps below.

### Metrics extraction

If you are using a metrics archive from the [metrics collector](https://github.com/puppetlabs/puppetlabs-puppet_metrics_collector/#sharing-metrics-data), create a directory named `metrics` and extract the archive to it.

```
mkdir metrics
tar xf <metrics_archives> -C metrics --strip-components 1
```

If using a PE support script, extract it and change to its top level directory.

```
tar xf <pe_support_script>.tar.gz
cd <pe_support_script>
```

Next, extract all individual archive files in the `metrics` directory:

```
find metrics/ -type f -name "*gz" -execdir tar xf "{}" \;
```

Lastly, delete any Puppet server metrics with errors. Currently, these will cause the `telegraf` process to exit upon encountering an error.  Delete these with:
```
find metrics/puppetserver -type f -name "*json" -size -1000c -delete
```

### Create an InfluxDB bucket and Grafana datasource

You may skip this step if using the default [organization](https://github.com/puppetlabs/puppet_operational_dashboards/blob/main/REFERENCE.md#initial_org) and [bucket](https://github.com/puppetlabs/puppet_operational_dashboards/blob/main/REFERENCE.md#initial_bucket) from this module, or otherwise have already created them.

An organization and bucket may be continuously enforced as part of a catalog compilation using resources from the `puppetlabs-influxdb` module.  See the [influxdb_org](https://github.com/puppetlabs/influxdb/blob/main/REFERENCE.md#influxdb_org) and [influxdb_bucket](https://github.com/puppetlabs/influxdb/blob/main/REFERENCE.md#influxdb_bucket) resources for more.

Alternatively, the [bucket_and_datasource class](https://github.com/puppetlabs/puppet_operational_dashboards/blob/main/examples/bucket_and_datasource.txt) shows how to create a bucket and Grafana datasource in an ad hoc manner using `puppet apply`.  This requires an Influxdb admin token to be saved to `~/.influxdb_token` and for the dependencies to be installed locally, e.g. with:

```
puppet module install puppetlabs/influxdb
puppet module install puppet/grafana
```

Next, save and configure the example file to `~/bucket_and_datasource.txt`:

```
# Example Puppet code to create an InfluxDB bucket and Grafana datasource.
# Intended to be used with `puppet apply`.  Fill in these values as needed:
#   <bucket_name>
#   <my_org>
#   <my_datasource>
class local_apply(
  String $influxdb_token_file = lookup(influxdb::token_file, undef, undef, $facts['identity']['user'] ? {
    'root'  => '/root/.influxdb_token',
    default => "/home/${facts['identity']['user']}/.influxdb_token"
})

){
  $token = file($influxdb_token_file)

  influxdb_bucket {'puppet_data':
    ensure => present,
    org    => 'puppetlabs',
  }

  grafana_datasource {'sample_datasource':
    grafana_user     => 'admin',
    grafana_password => 'admin',
    grafana_url      => "http://${facts['fqdn']}:3000",
    type             => 'influxdb',
    # This must match the namevar of the influxdb_bucket resource
    database         => 'puppet_data',
    url              => "https://${facts['fqdn']}:8086",
    access_mode      => 'proxy',
    is_default       => false,
    json_data        => {
      httpHeaderName1 => 'Authorization',
      httpMode        => 'GET',
      tlsSkipVerify   => true
    },
    secure_json_data => {
      httpHeaderValue1 => "Token ${token}",
    },
  }
}

include local_apply
```

And apply the code:

```
puppet apply ~/bucket_and_datasource.txt
```

For more information about the Grafana datasource, see the [puppet-grafana](https://github.com/voxpupuli/puppet-grafana/blob/master/REFERENCE.md#grafana_datasource) module.

### Run Telegraf to process and import the metrics

First, export your token described in the [requirements](#requirements).
```
export INFLUX_TOKEN=<token>
```
Then extract the archives, change to the appropriate directory as descriped in [metrics extraction](#metrics-extraction), and run Telegraf with the `--once` flag to import the metrics.  This can be done all at once:
```
telegraf --once --debug --config ~/telegraf.conf --config-directory ~/telegraf.conf.d/
```

Or one service at a time, e.g. for Puppet server
```
telegraf --once --debug --config ~/telegraf.conf --config ~/telegraf.conf.d/puppetserver.conf
```

See [troubleshooting](https://github.com/puppetlabs/puppet_operational_dashboards#troubleshooting) in the `README` for information on troubleshooting Telegraf errors.

