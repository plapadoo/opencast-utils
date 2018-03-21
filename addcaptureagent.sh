curl -i -s -f --digest -u opencast_system_account:CHANGE_ME --request POST -H "X-Requested-Auth: Digest" --data state=idle 'http://localhost:8080/capture-admin/agents/test'
