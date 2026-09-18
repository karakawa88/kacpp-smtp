#!/bin/bash

# function _end() {
#     pid=$(ps auxw | grep "/sbin/init" | awk '{print $2}')
#     kill -15 $pid
#     exit 0
# }
# 
# trap '_end' 15


# ユーザーアカウントの作成
if [[ -r /usr/local/etc/postfix/users.txt ]]; then
    /usr/local/sh/mail/users_add.sh /usr/local/etc/postfix/users.txt
fi

# mailのシステムログの出力先を環境変数で切り替える
# MAIL_LOG_HOSTに値があればホスト転送を使用するように設定する。
# ない場合は/var/log/mail.logに出力する設定にする。
if [[ -z $MAIL_LOG_HOST ]]; then
    sed -r -i 's/^(mail\..*)[ \t]+.*$/\1    -/var/log/mail.log/' \
        /etc/rsyslog.d/default.conf
else
    sed -r -i "s/^(mail\\..*)[ \t]+.*$/\\1     @@${MAIL_LOG_HOST}:514/" \
        /etc/rsyslog.d/default.conf
fi
# supervisord
# /usr/sbin/supervisord

exec /bin/systemd


