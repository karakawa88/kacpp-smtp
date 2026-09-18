#!/bin/bash

##
# 概要: ユーザーグループを作成する
# 説明: ユーザーグループをファイルから読みこんで複数のユーザーグループを作成する。
#       ユーザーグループファイルの形式は
#           type:user_name:uid:所属グループ[:passwd]
#       です。typeは作成するのはユーザーかグループを指定するものです。
#       ユーザー
#           user:user_name:uid:所属グループ[:passwd]
#       uidはユーザーIDでこれは2つ以上のHostで同じユーザーを作成するためである。
#       passwdはパスワードで省略可能でその場合ユーザー名がパスワードになる。
#       グループ
#           group:group_name:gid
#       ユーザーグループ共に無い場合は作成で
#       既にユーザー名とuidが一致して存在する場合は何もしない。
#       これらは一行でユーザーグループを一緒に指定してもよい。
#       先頭の#で初まる文字列はコメントとみなす。
#       
#       $1 ユーザーグループリストファイル
# ステータスコード:
#   0       ユーザーグループ追加成功
#   1       既にすべて存在する

##
# 概要: 引数にファイルが指定されていない時は標準入力から
# 説明: echo "group:mail:500" | add_usergroup_sync.sh 
#       みたいなことをやりたい。少ないユーザーグループでも簡単に作成できるように。
#
function stdio_userlist() {
    # 一時ファイルを作る
    tmpfile=$(mktemp)
    #標準入力
    read line 
    echo "$line" >tmpfile
}

#引数処理
userlist=""         # ユーザーグループリストファイル
tmpfile=""          # 標準入力から受けとる一時ファイル
if [[ $# -lt 1 ]];then
    stdio_userlist
    userlist=tmpfile
else
    userlist="$1"
fi

##
# 概要: 文字列からユーザーアカウントを追加する。
#
# ステータスコード:
#   0       ユーザー作成
#   その他は一つでも再作成や既に存在すれば0以外
#   1       ユーザー再作成
#   2       ユーザーが既に存在
#   3       ユーザーファイルリストの形式がまちがっている
sh=/bin/bash
ret=0
function str_user_add() {
    local str=$1
    # ユーザーリストファイルの形式チェック
    if echo "$str" | grep -v -E -q "^user:[a-zA-Z_]+:[0-9]+:[a-zA-Z_]+.*$" 2>/dev/null ; then
        return 3
    fi
    local cond=$(echo $str | sed -r 's/^([0-9a-zA-Z_-]+):.*$/\1/')
    local user=$(echo $str | sed -r 's/^user:([a-zA-Z_]+):[0-9]+.*$/\1/')
    local uid=$(echo $str | sed -r 's/^user:[a-zA-Z_-]+:([0-9]+).*$/\1/')
    local group=$(echo $str | sed -r 's/^user:[a-zA-Z_-]+:[0-9]+:([a-zA-Z_-]+)$/\1/')
    local password=$(echo $str | sed -r -n 's/^user:[a-zA-Z_-]+:[0-9]+:[a-zA-Z_-]+:(.*)$/\1/')
    # パスワード
    if [[ -z "$password" ]]; then
        password=$user
    fi
    echo "userinfo: type=$cond, user=$user, uid=$uid, group=$group, passwd=$password"
    
    # ユーザー作成
     cat /etc/passwd | grep -E -q "^${user}:x:${uid}:.*" >/dev/null 2>&1
     if [[ $? -ne 0 ]]; then
        useradd -m -u $uid -s $sh -d "/home/${user}"  \
                    -g $group -G $group $user
        if [[ $? -ne 0 ]]; then
            echo "ユーザー作成失敗: user=${user}, uid=${uid}" 1>&2
            return 4
        fi
        echo "${user}:${password}" | chpasswd
        echo "ユーザー作成: $user"
    # 既に存在
    else
        echo "既に存在: ${user}"
        return 2
    fi
    return 0
}
function str_group_add() {
    local str=$1
    # グループリストの形式チェック
    echo "$str" | grep -E -q "^group:[a-zA-Z_]+:[0-9]+" 2> /dev/null
    if [[ $? -ne 0 ]]; then
        return 3
    fi
    local cond=$(echo $str | sed -r 's/^([-_0-9a-zA-Z]+):.*$/\1/')
    local group=$(echo $str | sed -r 's/^group:([a-zA-Z_]+):.*$/\1/')
    local gid=$(echo $str | sed -r 's/^group:[a-zA-Z_]+:([0-9]+):.*$/\1/')
    echo "groupinfo: type=$cond, group=$group, gid=$gid"
    
    # グループ作成
    cat /etc/group | grep -E -q "^${group}:.*:${gid}:.*" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        groupadd -g $gid "$group"
        if [[ $? -ne 0 ]]; then
            echo "グループ作成失敗: group=${group}, gid=${gid}" 1>&2
            return 4
        fi
        echo "グループ作成: $group"
    # 既に存在
    else
        echo "既に存在: ${group}"
        return 2
    fi
    return 0
}


ret=0
kind=""
name=""
cat "$userlist" | while read line
do
    if echo $line | grep -E -q '(^#.*$)|(^[ \t]*$)' 2>/dev/null ; then
        continue;
    fi
    kind=$(echo $line | sed -r "s/^(user|group).*$/\1/")
    name=$(echo $line | sed -r "s/^(user|group):([a-zA-Z_]+):.*$/\2/")
    echo "type=$kind, name=$name"

    if [[ "$kind" == "user" ]]; then
        str_user_add $line
    elif [[ "$kind" == "group" ]]; then
        str_group_add "$line"
    else
        echo "リストの形式は(user|group):....:" 1>&2
        return 3;
    fi
    [[ $? -gt 0 ]] && ret=$?
done

exit "$ret"

