curl -v -u admin:opencast -H "Accept:application/v1.0.0+json" "http://localhost:8080/api/events/$1" | jq
