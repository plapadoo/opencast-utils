#!/usr/bin/env bash

set -eu

die() {
    echo "$1"
    exit 1
}

locate_file() {
  [ -f "$1" ] || die "Couldn't find $1"
}

[ -d "docs" ] || die "Please execute in the Opencast directory"

OC_VERSION="$(sed -e '/<version>/!d' -e 's/.*<version>//' -e 's#</version>.*##' pom.xml | head -n 1)"
OC_STORAGE_DIR="$HOME/opencast-temp-storage"

rm -rf "$OC_STORAGE_DIR"

echo "Recreating database"
mysql --user=root --password=password <<EOF
DROP DATABASE IF EXISTS opencast;
CREATE DATABASE opencast CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE TEMPORARY TABLES ON opencast.*
  TO 'opencast'@'localhost' IDENTIFIED BY 'dbpassword';
EOF

echo "Executing DDL"
mysql --user=root --password=password opencast < "docs/scripts/ddl/mysql5.sql"

cd build || die "Couldn't find build/"

ADMIN_TAR="opencast-dist-allinone-${OC_VERSION}.tar.gz"
PRESENTATION_TAR="opencast-dist-presentation-${OC_VERSION}.tar.gz"
locate_file "$ADMIN_TAR"
locate_file "$PRESENTATION_TAR"

echo "Removing old archive dirs"

ADMIN_DIR=opencast-dist-allinone
PRESENTATION_DIR=opencast-dist-presentation
rm -rf "$ADMIN_DIR"
rm -rf "$PRESENTATION_DIR"

echo "Extracting archives"
tar xf "$ADMIN_TAR"
tar xf "$PRESENTATION_TAR"

replace_checked() {
    hash_before="$(sha256sum < $1)"
    sed -i -e "s~$2~$3~" "$1"
    hash_after="$(sha256sum < $1)"
    [ "$hash_before" != "$hash_after" ] || die "replace $2 by $3 in $1 did nothing!"
}

replace_custom() {
    replace_checked "$ADMIN_DIR/etc/custom.properties" "$1" "$2"
    replace_checked "$PRESENTATION_DIR/etc/custom.properties" "$1" "$2"
}

uncomment_custom() {
    replace_custom "#\($1\)" "\1"
}

replace_custom "ddl.generation=true" "ddl.generation=false"
uncomment_custom "org.opencastproject.db.vendor=MySQL"
uncomment_custom "org.opencastproject.db.jdbc.driver=com.mysql.jdbc.Driver"
uncomment_custom "org.opencastproject.db.jdbc.url=jdbc:mysql://localhost/opencast"
uncomment_custom "org.opencastproject.db.jdbc.user=opencast"
uncomment_custom "org.opencastproject.db.jdbc.pass=dbpassword"
replace_custom "org.opencastproject.storage.dir=.*" "org.opencastproject.storage.dir=$OC_STORAGE_DIR"
replace_custom "#org.opencastproject.solr.dir=.*" "org.opencastproject.solr.dir=$OC_STORAGE_DIR/solr-indexes"
echo 'org.opencastproject.file.repo.url=${org.opencastproject.admin.ui.url}' >> "$ADMIN_DIR/etc/custom.properties"
echo 'org.opencastproject.file.repo.url=${org.opencastproject.admin.ui.url}' >> "$PRESENTATION_DIR/etc/custom.properties"
replace_checked "$PRESENTATION_DIR/etc/custom.properties" "org.opencastproject.server.url=http://localhost:8080" "org.opencastproject.server.url=http://localhost:8081"
replace_checked "$PRESENTATION_DIR/etc/org.ops4j.pax.web.cfg" "http.port=8080" "http.port=8081"

replace_checked "$PRESENTATION_DIR/etc/org.opencastproject.organization-mh_default_org.cfg" "port=8080" "port=8081"
replace_checked "$PRESENTATION_DIR/etc/org.opencastproject.organization-mh_default_org.cfg" "#\(prop.org.opencastproject.admin.ui.url=\)" "\1"
replace_checked "$PRESENTATION_DIR/etc/org.opencastproject.organization-mh_default_org.cfg" "#\(prop.org.opencastproject.file.repo.url=\)" "\1"
replace_checked "$ADMIN_DIR/etc/org.opencastproject.organization-mh_default_org.cfg" "#\(prop.org.opencastproject.engage.ui.url=\)" "\1"
replace_checked "$ADMIN_DIR/etc/org.opencastproject.organization-mh_default_org.cfg" "engage.ui.url=.*" "engage.ui.url=http://localhost:8081"
echo "dispatchinterval=0" >> "$PRESENTATION_DIR/etc/org.opencastproject.serviceregistry.impl.ServiceRegistryJpaImpl.cfg"

echo "Adding LTI to nodes"
replace_checked "$PRESENTATION_DIR/etc/security/mh_default_org.xml" "<!-- <ref bean=\"oauthProtectedResourceFilter\" /> -->" "<ref bean=\"oauthProtectedResourceFilter\" />"
replace_checked "$PRESENTATION_DIR/etc/org.opencastproject.kernel.security.OAuthConsumerDetailsService.cfg" "#\(oauth.consumer.[^=]*=\)" "\1"
replace_checked "$ADMIN_DIR/etc/security/mh_default_org.xml" "<!-- <ref bean=\"oauthProtectedResourceFilter\" /> -->" "<ref bean=\"oauthProtectedResourceFilter\" />"
replace_checked "$ADMIN_DIR/etc/org.opencastproject.kernel.security.OAuthConsumerDetailsService.cfg" "#\(oauth.consumer.[^=]*=\)" "\1"
uncomment_custom "org.opencastproject.security.custom.roles.pattern="
