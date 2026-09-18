#!/bin/bash

DKIM_HOME=/var/run/opendkim

/usr/sbin/opendkim -x /usr/local/etc/opendkim/opendkim.conf &

# OpenDKIMソケットファイル
while [[ ! -r ${DKIM_HOME}/opendkim.sock ]]
do
    true
done
chown opendkim.postfix /var/run/opendkim
chmod 3770 /var/run/opendkim
chown opendkim.postfix /var/run/opendkim/opendkim.sock
chmod 660 /var/run/opendkim/opendkim.sock

exit 0
