FROM alpine:3.24
LABEL maintainer="Adrian Dvergsdal [atmoz.net]"

# Steps done in one RUN layer:
# - Install upgrades and new packages
# - OpenSSH needs /var/run/sshd to run
# - Remove generic host keys, entrypoint generates unique keys
# - Remove weak (< 3072 bit) Diffie-Hellman moduli
# - Drop Alpine's fail2ban sshd jail (syslog based), see files/fail2ban
# - GNU grep: fail2ban's nftables action uses `grep -P`
RUN apk update && apk upgrade && \
    apk add bash shadow openssh-server-pam openssh-sftp-server \
        fail2ban nftables grep && \
    rm -rf /var/cache/apk/* && \
    ln -s /usr/sbin/sshd.pam /usr/sbin/sshd && \
    mkdir -p /var/run/sshd && \
    rm -f /etc/ssh/ssh_host_*key* && \
    if [ -f /etc/ssh/moduli ]; then \
        awk '$1 ~ /^#/ || $5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe && \
        if grep -qv '^#' /etc/ssh/moduli.safe; then mv /etc/ssh/moduli.safe /etc/ssh/moduli; else rm /etc/ssh/moduli.safe; fi; \
    fi && \
    rm -f /etc/fail2ban/jail.d/*.conf

COPY files/sshd_config /etc/ssh/sshd_config
COPY files/fail2ban/jail.local files/fail2ban/fail2ban.local /etc/fail2ban/
COPY files/create-sftp-user files/sftp-log /usr/local/bin/
COPY files/entrypoint /

EXPOSE 22

ENTRYPOINT ["/entrypoint"]
