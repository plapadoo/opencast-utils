#!/usr/bin/env bash

set -ue

curl \
  --cookie-jar /tmp/cookies.txt 
  --data "j_username=admin&j_password=opencast&_spring_security_remember_me=on"
  "http://localhost:8080/admin-ng/j_spring_security_check"
