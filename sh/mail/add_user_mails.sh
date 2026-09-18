#!/bin/bash

###
#  概要: 
#  説明:
#
#


user_mails="/home/user_mails"
if [[ $# -ge 1 ]]; then
    user_mails="$1"
fi

#メールユーザーの作成
$SH/mail/add_usergroup_sync.sh /usr/local/etc/userlist.txt

user=""
cat /usr/local/etc/userlist.txt | \
while read line; do
    echo $line | grep -E -q "(^#.*)|(^[ \t]*$)" 2>/dev/null
    [[ $? -eq 0 ]] && continue
    user=$(echo "$line" | cut -d ":" -f 2) 
    if [[ -d /home/"$user" ]]; then
        if [[ ! -d "$user_mails/$user" ]]; then
            mkdir "$user_mails/$user"
            chown $user:mail "$user_mails/$user"
            chmod 770 "$user_mails/$user"
        fi
        if [[ ! -L /home/"$user"/Mail ]]; then
           ln -s  $user_mails/$user /home/"$user"/Mail  
        fi
    else
        echo "user=$userのホームディレクトリが存在しません。"
    fi

done
