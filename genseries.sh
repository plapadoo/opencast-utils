for i in $(seq 1 10); do
    cp series.template.xml series.xml
    sed -i -e "s/TITLE/title $i/g" series.xml
    sed -i -e "s/SUBJECT/subject $i/g" series.xml
    sed -i -e "s/DESCRIPTION/descriotion $i/g" series.xml
    sed -i -e "s/PUBLISHER/publisher $i/g" series.xml
    curl -f -i --digest -u opencast_system_account:CHANGE_ME -H "X-Requested-Auth: Digest" localhost:8080/series -F series="<series.xml"
done
rm series.xml
