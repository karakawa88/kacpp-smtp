# kagalpandh/kacpp-smtp SMTPメールサーバー環境Dockerイメージ

## 概要
SMTPメールサーバーDockerイメージファイル。
SMTPサーバーにpostfixをビルドしてインストールしている。
SMTPサーバーに必要な各種サービスもインストールした。

## バージョン
postfix   3.7.3

## 使い方
```shell
docker image pull kagalpandh/kacpp-smtp
docker run -dit --name kacpp-smtp -p 25:25 -p 465:465 -p 587:587 \
    --privileged --cap-add=SYS_ADMIN -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v  /home/local_etc:/usr/local/etc -v /home:/home/mail_users kagalpandh/kacpp-smtp
#各種サービス起動
docker exec -i kacpp-smtp "/usr/local/sh/system/mail-system-init.sh"
```
systemdを起動するため--privileged --cap-add=SYS_ADMINのオプション指定は必要である。
systemctlがDockerfileで使用できないため各種サービスを起動する/usr/local/sh/system/mail-system-init.sh
がある。もしも必要なサービスのみ起動したいなら手動で設定する。

## SMTPサーバーpostfixと各種サービス
SMTPサーバーpostfixとそれと連携して使用できるサービスをインストールしてある。
またmailのログの出力のためrsyslogやメール送信プログラムmsmtpプログラムもインストールしてある。
以下に使用できる機能。
- DKIM
    - OpenDKIMがインストール。
- DMARC
    - OpenDMARCがインストール。
- clamav-milter
    - メールウイルスチェック
- python-policyd-spf
    - SPFチェッカー
- msmtp
    - メールクライアント
    - メールウイルスチェックでウイルスを発見した時にメールを送信できる。
これら複数のサービスはsystemdで起動される。
これらを全て起動して使用するには少し手順が必要である。
これから順番に説明していこうと思う。

## 設定ファイルとそれを配置するディレクトリ
まずpostfixやopendkimなどの設定ディレクトリとファイルを用意する。
postfixとopendkimとopendmarcとclamav-milterとpython-policyd-spfはこの名前のディレクトリで/usr/local/etcに配置する。
/usr/local/etcはマウントするようになっている。
各種設定ファイルの配置方法。
~~~
postfix
    /usr/local/etc/postfix
        main.cf
        master.cf
        smtpd.conf
            これはcyrus-saslが使用する設定ファイル。
            通常は/usr/lib/sasl2/smtpd.confだがこれにリンクを張りここのファイルを使用するようにしてある。
        aliases
            通常は/etc/aliasesにあるファイルだがこれにもリンクをここに張ってある。
opendkim
    /usr/local/etc/opendkim
        各種opendkimの設定ファイル。
        ディレクトリファイルの所有者とグループをopendkimにしておく必要がある。
opendmarc
    /usr/local/etc/opendmarc
    各種OpenDMARCの設定ファイル。
clamav
    /usr/local/etc/clamav
        clamav-milter.conf
            clamav-milterの設定ファイル。
~~~

# 各種サービスのユーザーグループ
またサービスが使用するユーザー・グループはホストとUIDとGIDを合わせる必要がある。
UIDとGIDの対応 ユーザー.グループの書式
postfix
~~~
ユーザー   postfix       1003
グループ    postfix     996
グループ    postdrop    997
opendkim
ユーザー    opendkim    113
グループ    opendkim    120
opendmarc
ユーザー    opendmarc   1004
グループ    opendmarc   994
clamav-milter
ユーザー    clamav      1005
グループ    clamav      993
~~~

## マウント
設定ファイルの格納場所/usr/local/etcとメールユーザーのホームディレクトリの場所/home/mail_usersはマウントする必要がある。

## ポート番号
ポート番号は25と465と587を使用するためポートフォワーディングの設定が必要。

## メールユーザーの追加
メールユーザーは/usr/local/sh/mailのusers_add.shシェルスクリプトで簡単に追加できる。
このシェルスクリプトは引数か/usr/local/etc/postfix/users.txtからユーザー情報を読み込みユーザー追加を行う。
このファイルをコンテナー起動前など上のディレクトリにusers.txtとして配置すれば自動で追加できる。
既存のシステムにメールユーザーを追加する場合はこのファイルにユーザー情報を追記しておけばよい。
users.txtの書式
ユーザー名:パスワード:ユーザーID
このシェルスクリプトが作成するユーザーのshellは/bin/shでグループはmailで固定される。
このシェルスクリプトのユーザーのホームディレクトリは/home/mail_users/ユーザー名であり
このシェルスクリプトではコンテナ側にホームディレクトリを作成しない。
そのためあらかじめユーザーをホスト側で用意し/home/mail_usersをマウントすることが推奨される。
ちなみに手動でコンテナ側にユーザーのホームディレクトリを用意することもできる。

## postfixと各種サービスの連携
OpenDKIMとOpenDMARCとclamav-milterはmilterを使用してpostfixと連携させる必要がある。
### ソケットファイルの使用
ソケットファイルを使用する場合は所有者をサーバーの所有者に(opendkimサーバーならopendkimユーザー)そしてグループを
postfixに読み書きさせるためにpostfixとして読み書きの権限を与える必要がある。
OpenDKIMの場合は/usr/local/sh/mail/opendkim.shでopendkimのソケットファイルに権限を与えてソケットファイルを使用できるように
してある。もしTCP/IPを使用したい場合は設定ファイルを変更する。
OpenDMARCの場合はソケットファイルが自分では使用できなかったためTCP/IPでやり取りするようにしている。
clamav-milterは以下のようにすればソケットファイルを使用できるようになる。
clamav-milter.conf
~~~
# Default: no default
MilterSocket /var/run/clamav/clamav-milter.sock
#MilterSocket inet:7357
# ソケットファイルのパーミッション
MilterSocketMode 660
# 停止時にソケットファイルを削除するか    
FixStaleSocket yes
~~~
clamav-milterはホストで起動しているclamdで連携することが想定されており
ウイルスチェックを実際行うのはclamdである。もしこのコンテナーでclamdを起動したいなら
clamdの設定ファイルとsystemdの設定ファイルを用意する必要がある。
### postfixでのmilter設定
main.cf
~~~
smtpd_milters =
    # OpenDKIM
    unix:/var/run/opendkim/opendkim.sock,
    # OpenDMARC
    inet:127.0.0.1:8893,
    # clamav-milter
    unix:/var/run/clamav/clamav-milter.sock
~~~
### python-policyd-spf
SPFチェッカーでrestrictionsでSPFチェックを行うことができる。
main.cf
~~~
smtpd_sender_restrictions = 
    check_sender_access hash:/usr/local/etc/postfix/sender_access
    reject_non_fqdn_sender,
    reject_unknown_sender_domain,
    check_policy_service unix:private/policy-spf
~~~
master.cf
~~~
# ファイルの最後に追記
policy-spf     unix  -       n       n       -       0       spawn
  user=nobody argv=/usr/local/python/bin/python3 /usr/local/python/bin/policyd-spf /etc/python-policyd-spf/policyd-spf.conf
~~~
Pythonは/usr/local/pythonにインストールされている。
/etc/python-policyd-spf/はリンクで設定ファイルは/usr/local/etc/python-policyd-spfに格納する必要がある。

## clamav-milterのメール発見時のメール送信
clamav-milterはメールからウイルスを発見するとメールで送信する機能がある。
これのメール送信は/usr/local/sh/mail/infected_message_handler.shが行う。
これでclamav-milter.confに適切な設定をすればメール送信ができるが
メール送信にはSMTP-AUTHの設定やSMTPメールサーバーなどの情報が必要である。
メール送信には上のシェルスクリプトの中でmsmtpを使用しておりその設定ファイルを
/usr/local/etc/mailに.clamavmsmtprcで用意する必要がある。
このファイルの所有者と権限はclamav 600でなければmsmtpは送信に失敗する。

## rsyslogとlogrotateとcron
システムログのmailを使用するためrsyslogを使用している。
デフォルトでは/var/log/mail.logにメールのログは送られる。
環境変数MAIL_LOG_HOSTにIPアドレス・ホスト名を指定してホスト転送設定を指定できる。
もしこの環境変数を使用しないならデフォルトの転送先(/var/log/mail.log)が使用される。
またmailファシリティのログを手動でホストに転送したいなら
/etc/rsyslog.d/default.confに以下のように設定する。
mail.*info          @@ホストのIPアドレスとホスト名:ポート番号(514)
でホストのrsyslogサーバーにも転送できる。
rsyslogを導入したためlogrotateもインストールしている。
cronにはaptをアップデートさせている。

## ユーザーのMaildirのバックアップ
ユーザーのメールディレクトリ(~/Maildir)を自動でバックアップできる。
それにはDockerコンテナーに環境変数MAILDIR_BACKUPにTRUEを設定する。
これを設定するとタイマーにバックアップ処理が追加される。
そしてバックアップ先として/destをbindマウントする。
バックアップファイル名はusers-mail-backup.tar.xzである。
もしこの環境変数を設定しない場合はタイマーに登録されずにバックアップは実行されない。
###それぞれのファイル
バックアップスクリプト:     /usr/local/sh/mail/users-mail-backup.sh
タイマー:                   /etc/systemd/system/user-maildir-backup.timer
サービス:                   /etc/systemd/system/user-maildir-backup.service

##ベースイメージ
kagalpandh/kacpp-pydev

# その他
DockerHub: [kagalpandh/kacpp-smtp](https://hub.docker.com/repository/docker/kagalpandh/kacpp-smtp)<br />
GitHub: [karakawa88/kacpp-smtp](https://github.com/karakawa88/kacpp-smtp)

