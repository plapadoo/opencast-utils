#!/bin/sh

curl \
  --verbose \
  --user admin:opencast \
  --header "Accept:application/v1.0.0+json" \
  "http://localhost:8080/api/series/$1" \
  | jq
