#!/usr/bin/env bash

for i in $(seq 1 10); do
  echo "event $i"
  curl \
    --fail \
    --include \
    --digest \
    --user opencast_system_account:CHANGE_ME \
    --header "X-Requested-Auth: Digest" \
    --form 'flavor=presentation/source' \
    --form 'BODY=@a.mp4' \
    --form title="$(telnet bofh.jeffballard.us 666 2>&- | grep 'Your excuse is:' | sed 's/^Your excuse is: //')" \
    --form creator="$(curl 'http://www.richyli.com/randomname/' | grep '(Try in ' | cut -d'(' -f1 | cut -d'>' -f2)" \
    localhost:8080/ingest/addMediaPackage/fast
done
