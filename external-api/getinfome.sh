set -eux

USER=admin
PASSWORD=opencast
SERVER=https://develop.opencast.org

curl -u $USER:$PASSWORD $SERVER/api/info/me
