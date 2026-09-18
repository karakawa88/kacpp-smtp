# PstgreSQL環境を持つdebianイメージ
# 日本語化も設定済み
FROM        kagalpandh/kacpp-gccdev AS builder
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
ENV         DEBIAN_FORONTEND=noninteractive
ENV         MSMTP_VERSION=1.8.22
ENV         MSMTP_SRC=msmtp-${MSMTP_VERSION}
ENV         MSMTP_SRC_FILE=${MSMTP_SRC}.tar.xz
ENV         MSMTP_GPG_PUB_KEY="key.txt"
ENV         MSMTP_GPG_PUB_KEY_URL="https://marlam.de/${MSMTP_GPG_PUB_KEY}"
ENV         MSMTP_URL="https://marlam.de/msmtp/releases/${MSMTP_SRC_FILE}"
ENV         MSMTP_DEST=${MSMTP_SRC}
# ENV         CYRUS_VERSION=2.1.27
# ENV         CYRUS_SRC=cyrus-sasl-${CYRUS_VERSION}
# ENV         CYRUS_SRC_FILE=${CYRUS_SRC}.tar.gz
# ENV         CYRUS_URL="https://github.com/cyrusimap/cyrus-sasl/archive/refs/tags/${CYRUS_SRC_FILE}"
# ENV         CYRUS_DEST=${CYRUS_SRC}
COPY        sh/     /usr/local/sh
# https://github.com/cyrusimap/cyrus-sasl/archive/refs/tags/cyrus-sasl-2.1.27.zip
# 開発環境インストール
RUN         apt update && \
            /usr/local/sh/system/apt-install.sh install gccdev.txt && \
            /usr/local/sh/system/apt-install.sh install mail-system-dev.txt && \
            pip3 install $(cat /usr/local/sh/pip-install/* |\
                grep -v -E '(^#.*$)|(^[ \t]*$)' | uniq | xargs) && \
            # msmtp
            # GPG Sign
            wget ${MSMTP_GPG_PUB_KEY_URL} && \
            gpg --import ${MSMTP_GPG_PUB_KEY} && \
            # msmstp download
            wget ${MSMTP_URL} && wget ${MSMTP_URL}.sig && \
            gpg --verify ${MSMTP_SRC_FILE}.sig ${MSMTP_SRC_FILE} && \
            # msmtpビルド
            # ./configure --prefix=... && make && make install
            tar -Jxvf ${MSMTP_SRC_FILE} && cd ${MSMTP_SRC} && \
                ./configure --prefix=/usr/local/${MSMTP_DEST} && \
                make && make install
            # cyrus-saslビルド
            # ./configure
            # make && make install
# ftp://ftp.porcupine.org/mirrors/project-history/postfix/official/postfix-3.5.2.tar.gz
# Postfixビルドとインストール
ENV         POSTFIX_VERSION=3.7.3
ENV         POSTFIX_GPG_PUB_KEY="wietse.pgp"
ENV         POSTFIX_GPG_PUB_URL="https://ghostarchive.org/postfix/postfix-release/${POSTFIX_GPG_PUB_KEY}"
ENV         POSTFIX_SRC=postfix-${POSTFIX_VERSION}
ENV         POSTFIX_SRC_FILE=${POSTFIX_SRC}.tar.gz
ENV         POSTFIX_URL="https://ghostarchive.org/postfix/postfix-release/official/${POSTFIX_SRC_FILE}"
ENV         POSTFIX_DEST=${POSTFIX_SRC}
RUN         wget ${POSTFIX_GPG_PUB_URL} && gpg --import ${POSTFIX_GPG_PUB_KEY} && \
            wget ${POSTFIX_URL} && wget ${POSTFIX_URL}.gpg2 && \
            gpg --verify ${POSTFIX_SRC_FILE}.gpg2 ${POSTFIX_SRC_FILE} && \
            tar -zxvf ${POSTFIX_SRC_FILE} && cd ${POSTFIX_SRC} && \
                make makefiles CCARGS="-DUSE_TLS -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl" \
                AUXLIBS="-L/usr/local/lib -lsasl2 -lssl -lcrypto" && \
                make && \
                mkdir /usr/local/${POSTFIX_DEST} && \
                make non-interactive-package install_root="/usr/local/${POSTFIX_DEST}"
# OpenDMARCのビルド
# URL: https://sourceforge.net/projects/opendmarc/files/opendmarc-1.3.2.tar.gz/download
ENV         OPENDMARC_VERSION=1.3.2
ENV         OPENDMARC_SRC=opendmarc-${OPENDMARC_VERSION}
ENV         OPENDMARC_SRC_FILE=${OPENDMARC_SRC}.tar.gz
ENV         OPENDMARC_URL=https://sourceforge.net/projects/opendmarc/files/${OPENDMARC_SRC_FILE}/download
ENV         OPENDMARC_DEST=${OPENDMARC_SRC}
RUN         wget ${OPENDMARC_URL} && tar -zxvf ${OPENDMARC_SRC_FILE} && cd ${OPENDMARC_SRC} && \
            ./configure --prefix=/usr/local/${OPENDMARC_DEST} && make && make install
# clamavのビルド
ENV         CLAMAV_VERSION=0.105.1
ENV         CLAMAV_SRC=clamav-${CLAMAV_VERSION}
ENV         CLAMAV_SRC_FILE=${CLAMAV_SRC}.tar.gz
ENV         CLAMAV_URL=https://www.clamav.net/downloads/production/${CLAMAV_SRC_FILE}
ENV         CLAMAV_DEST=${CLAMAV_SRC}
RUN         apt install -y curl && \
            cd ~/ && curl "https://sh.rustup.rs" -sSf >rustup.sh && \
            chmod 775 rustup.sh && ./rustup.sh -y && \
            source ~/.cargo/env && \
            python3 /usr/local/sh/python/fetch_gpg_pub_key.py \
                "http://www.clamav.net/downloads#collapsePGP" \
                "#collapsePGP pre" >clamav.pub && \
            gpg --import clamav.pub && \
            wget -O ${CLAMAV_SRC_FILE}.sig  ${CLAMAV_URL}.sig && wget -O ${CLAMAV_SRC_FILE} ${CLAMAV_URL} && \
            gpg --verify ${CLAMAV_SRC_FILE}.sig ${CLAMAV_SRC_FILE} && \
            tar -zxvf ${CLAMAV_SRC_FILE} &&  \
                cd ${CLAMAV_SRC} && mkdir build && cd build && \
                cmake .. \
                    -D CMAKE_INSTALL_PREFIX=/usr/local/${CLAMAV_DEST} \
                    -D DATABASE_DIRECTORY=/var/lib/clamav \
                -D ENABLE_JSON_SHARED=OFF &&\
                cmake --build . && \
                ctest && \
                cmake --build . --target install
# RUN         apt install -y clamav-milter
# クリーンアップ
RUN         apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*
FROM        kagalpandh/kacpp-pydev
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
USER        root
EXPOSE      25 587 465 2525
VOLUME      ["/home/mail_users", "/usr/local/etc"]
# メールクライアントMSMTP用環境変数
ENV         MSMTP_VERSION=1.8.22
ENV         MSMTP_DEST=msmtp-${MSMTP_VERSION}
# rsyslog用環境変数
ENV         SYSLOG_GID=110
ENV         SYSLOG_UID=104
# Postfix用環境変数
ENV         POSTFIX_VERSION=3.7.3
ENV         POSTFIX_SRC=postfix-${POSTFIX_VERSION}
ENV         POSTFIX_DEST=${POSTFIX_SRC}
# Postfix用ユーザー・グループ
ENV         POSTFIX_GROUP=postfix
ENV         POSTDROP=postdrop
ENV         POSTFIX_USER=postfix
ENV         PF_GID=996
ENV         PD_GID=997
ENV         PF_UID=1003
ENV         IDENT_TRUST_CERT=lets-encrypt-r3-cross-signed.pem
# OpenDKIM環境変数
ENV         OPENDKIM_UID=113
ENV         OPENDKIM_GID=120
ENV         OPENDKIM_USER=opendkim
ENV         OPENDKIM_GROUP=opendkim
# OpenDMARC環境変数
ENV         OPENDMARC_VERSION=1.3.2
ENV         OPENDMARC_DEST=opendmarc-${OPENDMARC_VERSION}
ENV         OPENDMARC_UID=1004
ENV         OPENDMARC_GID=994
ENV         OPENDMARC_USER=opendmarc
ENV         OPENDMARC_GROUP=opendmarc
# clamav-milter環境変数
ENV         CLAMAV_VERSION=0.105.1
ENV         CLAMAV_DEST=clamav-${CLAMAV_VERSION}
ENV         CLAMAV_UID=1005
ENV         CLAMAV_GID=993
ENV         CLAMAV_USER=clamav
ENV         CLAMAV_GROUP=clamav
# postfixはビルドされたものをコピーするため/var/spool/postfixと
# /var/lib/postfixディレクトリは作成されないので作成
# ついでにメール用シェルスクリプトディレクトリ/usr/local/sh/mailディレクトリ作成
RUN         mkdir /var/spool/postfix && mkdir /var/lib/postfix && \
            mkdir /usr/local/sh/mail
COPY        --from=builder /usr/local/${MSMTP_DEST}/ /usr/local
COPY        --from=builder /usr/local/${POSTFIX_DEST}/usr/ /usr/local
COPY        --from=builder /usr/local/${POSTFIX_DEST}/etc/ /usr/local/etc
COPY        --from=builder /usr/local/${OPENDMARC_DEST}/ /usr/local/
COPY        --from=builder /usr/local/${CLAMAV_DEST}/ /usr/local/
#パッケージのインストールを先に行う
# 設定ファイルのコピーの先にやらないと上書きされるかエラーでビルドできない
# COPY        --from=builder /usr/local/var/spool/postfix/ /var/spool/postfix
COPY        sh/  /usr/local/sh
# COPY        supervisord.conf /root
# COPY        .msmtprc /root
# https://letsencrypt.org/certs/lets-encrypt-r3-cross-signed.pem
RUN         apt update && \
            /usr/local/sh/system/apt-install.sh uninstall uninstall-exim.txt && \
            # rsyslog
            groupadd -g ${SYSLOG_GID} syslog && \
                useradd -u ${SYSLOG_UID} -s /bin/false -d /dev/null -g syslog -G syslog syslog && \
                chown -R root.syslog /var/log && chmod 3775 /var/log && \
            mkdir /var/log/mail && chown root.mail /var/log/mail && chmod 3775 /var/log/mail && ldconfig && \
#             mkdir /home/mail_users && \
            chown root.mail /home/mail_users && \
                chmod 3775 /home/mail_users && \
            /usr/local/sh/system/apt-install.sh install mail-system.txt && \
            # Postfix配置と設定
            # Postfixユーザー・グループ作成
            groupadd -g ${PF_GID} ${POSTFIX_GROUP} && groupadd -g ${PD_GID} ${POSTDROP} && \
                useradd -u ${PF_UID} -s /bin/false -d /dev/null -g ${POSTFIX_GROUP} \
                    -G "${POSTFIX_GROUP},${POSTDROP}" ${POSTFIX_USER} && \
                chown -R ${POSTFIX_USER}.${POSTFIX_GROUP} /var/spool/postfix && \
            # Postfix ディレクトリ配置
            test -d '/usr/libexec' || mkdir -p /usr/libexec && \
                chown postfix.postfix /var/lib/postfix && chmod 3775 /var/lib/postfix && \
                ln -s /usr/local/libexec/postfix /usr/libexec/postfix && \
                ln -s /usr/local/etc/postfix /etc/postfix && \
                chown root.postdrop /usr/local/sbin/post* && \
                chmod 2755 /usr/local/sbin/postqueue && \
                chmod 2755 /usr/local/sbin/postdrop && \
            # エイリアス
            test -r /etc/aliases && rm -rf /etc/aliases && \
                ln -s /usr/local/etc/aliases /etc/aliases && \
                ln -s /usr/local/etc/aliases.db /etc/aliases.db && \
            # SMTP-AUTH
            # 通常SASLの設定ファイルsmtpd.confは/usr/lib/sasl2にあるが
            # これを/usr/local/etc/postfix内にあると仮定してリンクを張る
            ln -s  /usr/local/etc/postfix/smtpd.conf  /usr/lib/sasl2/smtpd.conf && \
            # SSL
            # SSLで大抵LetsEncryptを使用するためISRGが署名した証明書を配置しなくてはならない。
            # しかしISRGの証明書は大抵の暗いアアントにはないのでIdentTrustの署名した証明書を使用する。
            wget https://letsencrypt.org/certs/${IDENT_TRUST_CERT} && \
                cp ${IDENT_TRUST_CERT} /etc/ssl/certs && \
                chmod 644 /etc/ssl/certs/${IDENT_TRUST_CERT} && \
            # SPF 受信側の検証 postfix pypolicyd-spf
            pip3 install py3dns && \
            pip3 install pyspf && \
            pip3 install pypolicyd-spf && \
            pip3 install authres && \
            # ユーザーがpython-policyd-spfを配置しなくてもデフォルトのディレクトリを配置
            mv /etc/python-policyd-spf /usr/local/etc && \
            ln -s /usr/local/etc/python-policyd-spf /etc/python-policyd-spf && \
            # OpenDKIMの設定
            # OpenDKIMはAPTで入れておりユーザーとグループopendkimは既に作成されているためコメントアウト
            # RUN         groupdel ${OPENDKIM_GROUP} && \
            userdel ${OPENDKIM_USER} && \
                groupadd -g ${OPENDKIM_GID} ${OPENDKIM_GROUP} && \
                useradd -r -u ${OPENDKIM_UID} -s /bin/false -d /dev/null \
                        -g ${OPENDKIM_GROUP} -G ${OPENDKIM_GROUP} ${OPENDKIM_USER} && \
            # /var/run/opendkimも既に作成されているためコメントアウト
            # RUN         mkdir /var/run/opendkim && \
            chown opendkim.postfix /var/run/opendkim && \
                chmod 3775 /var/run/opendkim && \
            # OpenDMARCの配置と設定
            groupadd -g ${OPENDMARC_GID} ${OPENDMARC_GROUP} && \
                useradd -u ${OPENDMARC_UID} -s /bin/false -d /dev/null \
                    -g ${OPENDMARC_GROUP} -G ${OPENDMARC_GROUP} ${OPENDMARC_USER} && \
                mkdir /var/run/opendmarc && chown opendmarc.postfix /var/run/opendmarc && \
                chmod 3775 /var/run/opendmarc && \
                mkdir /var/spool/opendmarc && chown opendmarc.opendmarc /var/spool/opendmarc && \
                chmod 3775 /var/spool/opendmarc && ldconfig && \
            # clamav-milter
            # clamavユーザーグループ作成とディレクトリの配置
#             groupdel clamav && userdel clamav && \
            groupadd -g ${CLAMAV_GID} ${CLAMAV_GROUP} && \
                useradd -u ${CLAMAV_UID} -s /bin/false -d /dev/null \
                    -g ${CLAMAV_GROUP} -G ${CLAMAV_GROUP} ${CLAMAV_USER} && \
                mkdir /var/run/clamav && chown ${CLAMAV_USER}.${POSTFIX_USER} /var/run/clamav && \
                    chmod 770 /var/run/clamav && \
                mkdir /var/log/clamav && chown clamav.clamav /var/log/clamav && \
                    chmod 770 /var/log/clamav && \
                chown -R postfix.clamav /usr/local/sh/mail && \
                    chmod 775 /usr/local/sh/mail && \
#                     chown clamav.clamav /usr/local/sh/mail/infected_message_handler.sh && \
#                     chmod 775 /usr/local/sh/mail/infected_message_handler.sh && \
            #systemdの設定
            # ENTRYPOINTとクリーンアップ
            chmod 775 /usr/local/sh/system/*.sh && \
            chmod 775 /usr/local/sh/mail/*.sh && \
            # なぜかSMTPサーバーexim4が入っておりそれが起動してpostfixの邪魔になるので削除
            apt remove --purge -y exim4-daemon-light exim4-daemon-heavy && \
            cd ~/ && apt clean && rm -rf /var/lib/apt/lists/* && rm *
# systemdやcron.dなどの設定ファイルはパッケージインストールの後に行うようにする
# それによって上書きやエラーでビルドできないことを避けるため
COPY        etc/systemd/system/  /etc/systemd/system/
COPY        etc/tmpfiles.d/     /etc/tmpfiles.d/
COPY        etc/logrotate.d/    /etc/logrotate.d
COPY        etc/cron.d/    /etc/cron.d
COPY        etc/rsyslog.conf /etc
COPY        etc/rsyslog.d/ /etc/rsyslog.d
# 設定ファイルのパーミッションと所有者の設定
# logrotateとcron
RUN         chown -R root.root /etc/logrotate.d && chmod 644 /etc/logrotate.d/* && \
            chown -R root.root /etc/cron.d && chmod 644 /etc/cron.d/*
ENTRYPOINT  ["/usr/local/sh/system/mail-system.sh"]
