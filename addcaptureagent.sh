#!/bin/env bash

set -ue

curl \
  --include \
  --fail \
  --digest \
  --user opencast_system_account:CHANGE_ME \
  --request POST \
  --header "X-Requested-Auth: Digest" \
  --data state=idle \
  'http://localhost:8080/capture-admin/agents/test'
