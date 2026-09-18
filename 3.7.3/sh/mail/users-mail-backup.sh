#!/bin/bash

##
# 概要: ユーザーのメールのバックアップを行うスクリプト。
# 説明: ユーザーのメーディレクトリ Maildirを全てtarで固めてバックアップする。
# ステータスコード:
#   0       正常
#   1       ユーザーのホームディレクトリが格納されたディレクトリがない
#   2       バックアップ先ディレクトリがない
#   3       ユーザーのMaildirがひとつも見つからない
#   4       tarでエラー
#

# 各ユーザーのHomeディレクトリがあるディレクトリ
USERS_HOME_DIR="/home/mail_users"
# バックアップ先ディレクトリ
DEST="/dest"
# バックアップファイル
BACKUP_FILE="mail_users-backup.tar.xz"
# tar コマンドのオプション
# COMPRESS_COMMAND=${COMPRESS_COMMAND:-"xz -T 0"}
TAR_WARN_ERR_OPTIONS=" --warning=no-file-changed --warning=no-file-removed --warning=no-file-shrank "
# TAR_OPTIONS=" -cJvf $BACKUP_FILE --use-compress-prog='$COMPRESS_COMMAND' $TAR_WARN_ERR_OPTIONS "
TAR_OPTIONS=" -cJf $BACKUP_FILE  $TAR_WARN_ERR_OPTIONS "

##
# 概要: ログをsyslogと標準出力に書き出す。
# 説明: 第一引数に指定したメッセージを標準出力とsyslogに書き出す。
#       syslogのファシリティとプライオリティはmail.infoである。
# 引数: $1  メッセージ
function log_info() {
    local mess = $1

    logger -p mail.info -t MaildirBackup "$mess"
    echo "$mess"
    return 0
}
##
# 概要: エラーログをsyslogと標準エラー出力に書き出す。
# 説明: 第一引数に指定したメッセージを標準エラー出力とsyslogに書き出す。
#       syslogのファシリティとプライオリティはmail.errである。
# 引数: $1  メッセージ
function log_err() {
    local mess = $1

    logger -p mail.err -t MaildirBackup "$mess"
    echo "$mess" 1>&2
    return 0
}

# ユーザーたちのHOMEディレクトリ
if [[ ! -d "$USERS_HOME_DIR" ]]
then
    log_err "ユーザーのHomeディレクトリが見つかりません。[$USERS_HOME_DIR]"
    exit 1
fi
# バックアップ出力先
if [[ ! -d "$DEST" ]]
then
    log_err "バックアップ先ディレクトリが見つかりません。[$DEST]"
    exit 2
fi

# バックアップするユーザーのメールのディレクトリ一覧の取得
log_info "ユーザーのメールのバックアップ(Maildir)"
log_info "バックアップ先ディレクトリ: $DEST"
log_info "バックアップファイル: $BACKUP_FILE"

# バックアップ元のリストスペース区切り
SRC=""
shopt -s lastpipe
find "$USERS_HOME_DIR" -maxdepth 1 -type d -print |\
while read dir
do
    if [[ -d "$dir/Maildir" ]]
    then
        SRC="$SRC ${dir}/Maildir "
    else
        continue
    fi
done
[[ -z "$SRC" ]] && log_err "ユーザーのMaildirがひとつも見つかりません。" && exit 3
log_info "バックアップするメール: $SRC"

cd $DEST
log_info "tarのオプション ${TAR_OPTIONS}"
tar ${TAR_OPTIONS} $SRC
ret=$?
if (( $ret > 2 )) 
then
    echo "Error: tarバックアップエラー" 1>&2
    exit 4
fi
log_info "ユーザーメールのバックアップ完了"

exit 0
