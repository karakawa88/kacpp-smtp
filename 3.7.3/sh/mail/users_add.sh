#!/bin/bash

# メールアカウントのホームディレクトリ
mail_users_dir="/home/mail_users"
# メールアカウントのグループ
mail_group="mail"
# ユーザーのシェル
sh="/bin/sh"

# ユーザーのリスト
if [[ $# != 0 ]]; then
    USERS_LIST=$1
else
    USERS_LIST="/usr/local/etc/postfix/users.txt"
fi

# cat - <<EOS >users.txt
# hogehoge:2300:testuser
# aoritarou:2400:sample
# EOS

##
# 概要: 文字列からユーザーアカウントを追加する。
#
function str_useradd() {
    local str=$1
    local user=$(echo $str | sed -r 's/^([-_0-9a-zA-Z#]+):.*:[0-9]+$/\1/')
    local passwd=$(echo $str | sed -r 's/^.*:(.*):[0-9]+$/\1/')
    local user_id=$(echo $str | sed -r 's/^.*:.*:([0-9]+)$/\1/')

    cat /etc/passwd | grep -E -q "^${user}" >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        useradd -M -u $user_id -s $sh -d ${mail_users_dir}/${user} \
                    -g $mail_group -G $mail_group $user
        echo "${user}:${passwd}" | chpasswd
    fi
    return 0
}

cat $USERS_LIST | while read line
do
    echo $line | grep -E -q '^#|^[ \t]*$' >/dev/null 2>&1
    if [[ $? == 0 ]]; then
        continue
    fi
    str_useradd $line
done


