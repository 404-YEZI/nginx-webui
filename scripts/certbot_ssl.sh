#!/bin/bash
set -e
# 接收参数：domain email ssl_dir
DOMAIN=$1
EMAIL=$2
SSL_DIR=$3

# 校验参数
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ] || [ -z "$SSL_DIR" ]; then
    echo "参数错误：需要域名、邮箱、证书保存目录"
    exit 1
fi

# 申请证书（nginx插件，自动配置）
certbot certonly --nginx -d $DOMAIN --email $EMAIL --agree-tos --non-interactive --no-eff-email

# 复制证书到指定目录（避免certbot默认目录权限问题）
CERTBOT_DIR="/etc/letsencrypt/live/$DOMAIN"
if [ -d "$CERTBOT_DIR" ]; then
    cp -f $CERTBOT_DIR/fullchain.pem $SSL_DIR/$DOMAIN.crt
    cp -f $CERTBOT_DIR/privkey.pem $SSL_DIR/$DOMAIN.key
    chmod 644 $SSL_DIR/$DOMAIN.crt $SSL_DIR/$DOMAIN.key
    # 设置自动续期（每月1号执行）
    CRON_CMD="0 0 1 * * certbot renew --quiet && systemctl reload nginx"
    grep -qxF "$CRON_CMD" /etc/crontab || echo "$CRON_CMD" >> /etc/crontab
    echo "证书申请成功，已配置自动续期，证书文件：$SSL_DIR/$DOMAIN.crt | $SSL_DIR/$DOMAIN.key"
else
    echo "certbot证书生成失败，未找到目录：$CERTBOT_DIR"
    exit 1
fi