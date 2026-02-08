#!/bin/bash
set -e
# 接收参数：backup_file nginx_conf_d
BACKUP_FILE=$1
NGINX_CONF_D=${2:-/etc/nginx/conf.d}

# 校验参数
if [ ! -f "$BACKUP_FILE" ] || [ ! -d "$NGINX_CONF_D" ]; then
    echo "备份文件或配置目录不存在"
    exit 1
fi

# 解压回滚（覆盖现有配置）
unzip -q -o $BACKUP_FILE -d /
# 权限配置
chmod 644 $NGINX_CONF_D/*.conf
chown root:root $NGINX_CONF_D/*.conf

echo "已从备份包$BACKUP_FILE回滚配置到$NGINX_CONF_D"