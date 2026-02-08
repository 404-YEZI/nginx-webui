#!/bin/bash
set -e
# 接收参数：backup_dir nginx_conf_d
BACKUP_DIR=${1:-/tmp/nginx_backup}
NGINX_CONF_D=${2:-/etc/nginx/conf.d}
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/nginx_config_$DATE.zip"

# 初始化目录
mkdir -p $BACKUP_DIR

# 压缩备份
zip -q -r $BACKUP_FILE $NGINX_CONF_D

# 删除30天前的备份（轻量化，避免磁盘占满）
find $BACKUP_DIR -name "nginx_config_*.zip" -mtime +30 -delete

# 输出结果
echo "备份文件：$BACKUP_FILE，大小：$(du -h $BACKUP_FILE | awk '{print $1}')"