#!/bin/bash

while getopts ":t:m:s:c" opt; do
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
      cleanup='true'
      ;;
    *)
      echo "WARN: invalid option $opt received"
  esac
done

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

out="$(telegraf --once --debug --config "${telegraf_dir}/telegraf.conf" --config-directory "${telegraf_dir}/telegraf.conf.d")"

if [[ $cleanup == true ]]; then
  [[ -e ${metrics_dir}/metrics ]] && rm "${metrics_dir}/metrics" -rf
  [[ -e $_tmp ]] && rm "$_tmp" -rf
  [[ -e $support_script ]] && rm "$support_script"
fi


echo "$out"
