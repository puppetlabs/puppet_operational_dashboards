#!/bin/bash

conf_dir="$1"
metrics_dir="$2"
cleanup="$3"

cd "$metrics_dir" || exit 1
find metrics -type f -name "*gz" -execdir tar xf "{}" \;

out="$(telegraf --once --debug --config "${conf_dir}/telegraf.conf" --config-directory "${conf_dir}/telegraf.conf.d")"

if [[ $cleanup == true ]] && [[ -e ${metrics_dir}/metrics ]]; then
  rm "${metrics_dir}/metrics" -rf
fi

echo "$out"
