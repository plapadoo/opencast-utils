for i in $(seq 1 10); do
    curl -f -i --digest -u opencast_system_account:CHANGE_ME -H "X-Requested-Auth: Digest" localhost:8080/ingest/addMediaPackage/fast -F 'flavor=presentation/source' -F 'BODY=@a.mp4' -F title="`telnet bofh.jeffballard.us 666 2>&- | grep 'Your excuse is:' | sed 's/^Your excuse is: //'`" -F creator="`curl 'http://www.richyli.com/randomname/' | grep '(Try in ' | cut -d'(' -f1 | cut -d'>' -f2`"
done
