#!/usr/bin/env bash

set -ue

for i in $(seq 1 10); do
  cp series.template.xml series.xml
  sed -i -e "s/TITLE/title $i/g" series.xml
  sed -i -e "s/SUBJECT/subject $i/g" series.xml
  sed -i -e "s/DESCRIPTION/descriotion $i/g" series.xml
  sed -i -e "s/PUBLISHER/publisher $i/g" series.xml
  curl \
    --fail \
    --include \
    --digest \
    --user opencast_system_account:CHANGE_ME \
    --header "X-Requested-Auth: Digest" \
    --form series="<series.xml" \
    http://localhost:8080/series
done
rm series.xml
