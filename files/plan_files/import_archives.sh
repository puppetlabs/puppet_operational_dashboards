#!/bin/bash

while getopts ":t:m:s:c:" opt; do
  case $opt in
    t)
      telegraf_dir="$OPTARG"
      ;;
    m)
      metrics_dir="$OPTARG"
      ;;
    s)
      support_script="$OPTARG"
      ;;
    c)
      cleanup="$OPTARG"
      ;;
    *)
      echo "WARN: invalid option $opt received"
  esac
done

outfile="$(mktemp -p "$telegraf_dir")"

if [[ $support_script ]]; then
  _tmp="$(mktemp -d -p "$telegraf_dir")"

  tar xf "$support_script" -C "$_tmp" --strip-components=1 || {
    echo "Failed to extract $support_script"
    exit 1
  }

  cd "$_tmp" || exit 1
else
  cd "$metrics_dir" || exit 1
fi

find metrics -type f -name "*gz" -execdir tar xf "{}" \;

telegraf --once --debug --config "${telegraf_dir}/telegraf.conf" --config-directory "${telegraf_dir}/telegraf.conf.d" >"$outfile" 2>&1

# Only load one set of sar metrics from either the sa?? files, or from the metrics collector, preferring sa?? files
for f in metrics/sa/sa??; do
  if [[ -e $f ]]; then
    have_system_sar=yes
    break
  fi
done

if [[ $have_system_sar ]]; then
  telegraf --once --debug --config "${telegraf_dir}/telegraf.conf" --config "${telegraf_dir}/system_sar.conf" >>"$outfile" 2>&1
else
  telegraf --once --debug --config "${telegraf_dir}/telegraf.conf" --config "${telegraf_dir}/sar.conf" >>"$outfile" 2>&1
fi


if [[ $cleanup == true ]]; then
  [[ -e ${metrics_dir}/metrics ]] && rm -rf "${metrics_dir}/metrics"
  [[ -e $_tmp ]] && rm -rf "$_tmp"
  [[ -e $support_script ]] && rm "$support_script"
fi

cat "$outfile"
