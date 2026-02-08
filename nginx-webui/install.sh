#!/bin/bash
set -e
# 颜色输出（友好提示）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为root
if [ $EUID -ne 0 ]; then
    echo -e "${RED}❌ 错误：请以root权限运行此脚本${NC}"
    exit 1
fi

# 检查系统是否为Debian/Ubuntu
if [ ! -f /etc/debian_version ]; then
    echo -e "${RED}❌ 错误：仅支持Debian/Ubuntu系统（推荐Debian 12）${NC}"
    exit 1
fi

# 第一步：更新系统并安装基础依赖
echo -e "${YELLOW}【1/6】更新系统并安装基础依赖...${NC}"
apt update -y && apt upgrade -y
apt install -y nginx=1.28.* git python3 python3-pip unzip ufw certbot python3-certbot-nginx curl wget
# 确保Nginx为1.28稳定版
nginx -v | grep -q "1.28" || { echo -e "${RED}❌ Nginx 1.28安装失败${NC}"; exit 1; }
echo -e "${GREEN}✅ 基础依赖安装完成${NC}"

# 第二步：创建项目目录并拉取仓库
echo -e "${YELLOW}【2/6】拉取Nginx WebUI仓库...${NC}"
PROJECT_DIR="/opt/nginx-webui"
rm -rf $PROJECT_DIR || true
git clone -b nginx https://github.com/404-YEZI/nginx-webui.git $PROJECT_DIR
cd $PROJECT_DIR
echo -e "${GREEN}✅ 仓库拉取完成${NC}"

# 第三步：赋予脚本执行权限
echo -e "${YELLOW}【3/6】配置文件权限...${NC}"
chmod +x run.py
chmod +x scripts/*.sh
chmod -R 755 $PROJECT_DIR
echo -e "${GREEN}✅ 权限配置完成${NC}"

# 第四步：开放8888端口（防火墙）
echo -e "${YELLOW}【4/6】配置防火墙，开放8888端口...${NC}"
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1
ufw allow 8888/tcp > /dev/null 2>&1
ufw reload > /dev/null 2>&1
echo -e "${GREEN}✅ 防火墙配置完成${NC}"

# 第五步：启动WebUI服务
echo -e "${YELLOW}【5/6】启动Nginx WebUI服务...${NC}"
python3 run.py
echo -e "${GREEN}✅ 服务启动完成${NC}"

# 第六步：设置开机自启（crontab，轻量化）
echo -e "${YELLOW}【6/6】设置开机自启...${NC}"
CRON_CMD="@reboot root cd $PROJECT_DIR && python3 run.py"
grep -qxF "$CRON_CMD" /etc/crontab || echo "$CRON_CMD" >> /etc/crontab
update-rc.d cron enable > /dev/null 2>&1
service cron restart > /dev/null 2>&1
echo -e "${GREEN}✅ 开机自启配置完成${NC}"

# 安装完成提示
echo -e "\n${GREEN}🎉 **************************${NC}"
echo -e "${GREEN}🎉 Nginx WebUI安装成功！${NC}"
echo -e "${GREEN}🎉 **************************${NC}"
echo -e "${YELLOW}💡 核心提示：${NC}"
echo -e "1. 访问地址：http://你的服务器IP:8888"
echo -e "2. 所有Nginx操作均为可视化点击，无需代码"
echo -e "3. 忘记IP可执行：hostname -I"
echo -e "4. 停止服务可执行：pkill -f 'python3 /opt/nginx-webui/api/app.py'"
echo -e "${GREEN}🎉 开始使用吧！${NC}"