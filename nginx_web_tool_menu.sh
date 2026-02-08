#!/bin/bash
set -e

# ===================== 新增：前置核心适配（全新系统必加） =====================
# 1. 强制Root权限（所有操作需Root）
if [ $UID -ne 0 ]; then
    echo -e "\033[0;31m错误：必须以Root用户执行！\033[0m"
    # 自动尝试sudo重执行
    if command -v sudo &>/dev/null; then
        sudo bash "$0" "$@"
        exit $?
    fi
    exit 1
fi

# 2. 修复Windows换行符（全新系统下载脚本后避免执行报错）
sed -i 's/\r$//' "$0" &>/dev/null || true

# 3. 定义颜色（兼容无颜色终端）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 重置颜色

# ===================== 原配置项（仅修改仓库地址提示） =====================
# 配置项（请修改为你的仓库地址和端口）
NGINX_CONF_DIR="/etc/nginx/conf.d"
WEBUI_DIR="/usr/share/nginx/html"
WEBUI_REPO="https://你的仓库地址.git"  # 【必改】替换为你的Web-UI仓库（如GitHub/Gitee）
LOG_FILE="/var/log/nginx-webui.log"
NGINX_PORT=80          # Nginx默认端口
WEBUI_PORT=8080        # Web-UI端口（根据你的项目调整）
REQUIRED_PORTS=("$NGINX_PORT" "$WEBUI_PORT")  # 需要放行的端口

# ===================== 新增：补全最小化系统依赖（如ss命令、防火墙工具） =====================
install_minimal_deps() {
    echo -e "${YELLOW}安装全新系统最小化依赖...${NC}"
    check_os
    if [ "$OS" = "centos" ]; then
        # CentOS最小化系统缺firewalld、iproute2（ss命令）、sudo等
        yum install -y firewalld iproute2 sudo > $LOG_FILE 2>&1
        systemctl enable --now firewalld > $LOG_FILE 2>&1 || true
    else
        # Debian/Ubuntu最小化系统缺ufw、iproute2
        apt update > $LOG_FILE 2>&1
        apt install -y ufw iproute2 sudo > $LOG_FILE 2>&1
        ufw enable > $LOG_FILE 2>&1 || true
    fi
    echo -e "${GREEN}最小化依赖安装完成${NC}"
}

# ===================== 原工具函数（仅修改firewall_allow_port，兼容工具未装场景） =====================
# 检测系统发行版
check_os() {
    if [ -f /etc/redhat-release ]; then
        OS="centos"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        echo -e "${RED}不支持的系统（仅支持CentOS/RHEL、Debian/Ubuntu）${NC}" | tee -a $LOG_FILE
        exit 1
    fi
}

# 检测Nginx是否安装
check_nginx_installed() {
    if command -v nginx &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 检测Web-UI是否安装（修复原逻辑：index.html是文件，原判断有误）
check_webui_installed() {
    if [ -f "$WEBUI_DIR/index.html" ] || [ -n "$(ls -A $WEBUI_DIR)" ]; then
        return 0
    else
        return 1
    fi
}

# 检测端口是否监听
check_port_listen() {
    local port=$1
    if ss -tulpn | grep -q ":$port "; then
        return 0
    else
        return 1
    fi
}

# 检测IP+端口是否可达
check_ip_reachable() {
    local ip=$1
    local port=$2
    if timeout 2 bash -c "echo > /dev/tcp/$ip/$port"; then
        return 0
    else
        return 1
    fi
}

# 防火墙放行端口（新增：兼容防火墙未装场景）
firewall_allow_port() {
    check_os
    # 先装防火墙工具（全新系统可能缺失）
    install_minimal_deps
    
    for port in "${REQUIRED_PORTS[@]}"; do
        if [ "$OS" = "centos" ]; then
            firewall-cmd --permanent --add-port=$port/tcp > $LOG_FILE 2>&1
            firewall-cmd --reload > $LOG_FILE 2>&1
        else
            ufw allow $port/tcp > $LOG_FILE 2>&1
            ufw reload > $LOG_FILE 2>&1
        fi
        echo "放行端口 $port" | tee -a $LOG_FILE
    done
}

# ===================== 原核心功能函数（无修改） =====================
# 1. 安装Nginx
install_nginx() {
    check_os
    echo -e "${YELLOW}开始安装Nginx...${NC}" | tee -a $LOG_FILE
    if check_nginx_installed; then
        echo -e "${GREEN}Nginx已安装${NC}" | tee -a $LOG_FILE
        return
    fi

    if [ "$OS" = "centos" ]; then
        yum install -y epel-release > $LOG_FILE 2>&1
        yum install -y nginx > $LOG_FILE 2>&1
    else
        apt update > $LOG_FILE 2>&1
        apt install -y nginx > $LOG_FILE 2>&1
    fi

    systemctl enable nginx > $LOG_FILE 2>&1
    systemctl start nginx > $LOG_FILE 2>&1

    if check_nginx_installed; then
        echo -e "${GREEN}Nginx安装成功${NC}" | tee -a $LOG_FILE
    else
        echo -e "${RED}Nginx安装失败，查看日志: $LOG_FILE${NC}" | tee -a $LOG_FILE
    fi
}

# 2. 安装Web-UI
install_webui() {
    echo -e "${YELLOW}开始安装Web-UI...${NC}" | tee -a $LOG_FILE
    if check_webui_installed; then
        echo -e "${GREEN}Web-UI已安装${NC}" | tee -a $LOG_FILE
        return
    fi

    # 安装git（依赖）
    if ! command -v git &>/dev/null; then
        install_deps
    fi

    # 拉取你的仓库并部署
    rm -rf /tmp/webui_temp
    git clone $WEBUI_REPO /tmp/webui_temp > $LOG_FILE 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}拉取Web-UI仓库失败，查看日志: $LOG_FILE${NC}" | tee -a $LOG_FILE
        return
    fi

    # 同步到Nginx目录
    cp -rf /tmp/webui_temp/* $WEBUI_DIR/ > $LOG_FILE 2>&1
    chown -R nginx:nginx $WEBUI_DIR > $LOG_FILE 2>&1

    # 生成Web-UI配置文件
    cat > $NGINX_CONF_DIR/webui.conf << EOF
server {
    listen $WEBUI_PORT;
    server_name _;
    root $WEBUI_DIR;
    index index.html index.htm;

    access_log /var/log/nginx/webui_access.log;
    error_log /var/log/nginx/webui_error.log;
}
EOF

    # 重启Nginx
    systemctl restart nginx > $LOG_FILE 2>&1

    if check_webui_installed; then
        echo -e "${GREEN}Web-UI安装成功${NC}" | tee -a $LOG_FILE
    else
        echo -e "${RED}Web-UI安装失败，查看日志: $LOG_FILE${NC}" | tee -a $LOG_FILE
    fi
}

# 3. 安装Web-UI依赖（git、依赖包等）
install_deps() {
    echo -e "${YELLOW}开始安装依赖...${NC}" | tee -a $LOG_FILE
    check_os
    if [ "$OS" = "centos" ]; then
        yum install -y git wget > $LOG_FILE 2>&1
    else
        apt install -y git wget > $LOG_FILE 2>&1
    fi

    if command -v git &>/dev/null; then
        echo -e "${GREEN}依赖安装成功${NC}" | tee -a $LOG_FILE
    else
        echo -e "${RED}依赖安装失败，查看日志: $LOG_FILE${NC}" | tee -a $LOG_FILE
    fi
}

# 4. 检查安装状态（Nginx+Web）
check_install_status() {
    echo -e "\n===== 安装状态检查 ====="
    # Nginx状态
    if check_nginx_installed; then
        echo -e "Nginx: ${GREEN}已安装${NC}"
    else
        echo -e "Nginx: ${RED}未安装${NC}" | tee -a $LOG_FILE
    fi

    # Web-UI状态
    if check_webui_installed; then
        echo -e "Web-UI: ${GREEN}已安装${NC}"
    else
        echo -e "Web-UI: ${RED}未安装${NC}" | tee -a $LOG_FILE
    fi
}

# 5. 运行状态子菜单
run_status_menu() {
    while true; do
        echo -e "\n===== 运行状态子菜单 ====="
        echo "1. Nginx运行状态/重启"
        echo "2. Web-UI页面运行状态/重启"
        echo "3. 端口监听状态"
        echo "q. 退出"
        echo "====================================="
        read -p "请输入操作编号: " opt

        case $opt in
            1)
                # Nginx状态+重启
                echo -e "\n===== Nginx运行状态 ====="
                if systemctl is-active --quiet nginx; then
                    echo -e "状态: ${GREEN}运行中${NC}"
                else
                    echo -e "状态: ${RED}未运行${NC}" | tee -a $LOG_FILE
                    echo -e "${YELLOW}正在重启Nginx...${NC}"
                    systemctl restart nginx > $LOG_FILE 2>&1
                    if systemctl is-active --quiet nginx; then
                        echo -e "${GREEN}Nginx重启成功${NC}"
                    else
                        echo -e "${RED}Nginx重启失败，查看日志: $LOG_FILE${NC}" | tee -a $LOG_FILE
                    fi
                fi
                ;;
            2)
                # Web-UI状态+重启（重启Nginx即可刷新Web-UI）
                echo -e "\n===== Web-UI运行状态 ====="
                if check_webui_installed && check_port_listen $WEBUI_PORT; then
                    echo -e "状态: ${GREEN}运行中${NC}"
                else
                    echo -e "状态: ${RED}未运行${NC}" | tee -a $LOG_FILE
                    echo -e "${YELLOW}正在重启Nginx刷新Web-UI...${NC}"
                    systemctl restart nginx > $LOG_FILE 2>&1
                    if check_port_listen $WEBUI_PORT; then
                        echo -e "${GREEN}Web-UI重启成功${NC}"
                    else
                        echo -e "${RED}Web-UI重启失败，查看日志: $LOG_FILE${NC}" | tee -a $LOG_FILE
                    fi
                fi
                ;;
            3)
                # 端口监听状态
                echo -e "\n===== 端口监听状态 ====="
                for port in "${REQUIRED_PORTS[@]}"; do
                    if check_port_listen $port; then
                        echo -e "端口 $port: ${GREEN}已监听${NC}"
                    else
                        echo -e "端口 $port: ${RED}未监听${NC}" | tee -a $LOG_FILE
                    fi
                done
                ;;
            q|Q)
                break
                ;;
            *)
                echo -e "${RED}无效输入${NC}" | tee -a $LOG_FILE
                ;;
        esac
    done
}

# 6. 其他子菜单
other_menu() {
    while true; do
        echo -e "\n===== 其他子菜单 ====="
        echo "1. 查看当前IP地址"
        echo "2. 正在监听端口"
        echo "3. 查看异常日志"
        echo "4. 刷新所有转发配置文件使其生效"
        echo "5. 防火墙放行Nginx+WebUI所需端口"
        echo "q. 退出"
        echo "====================================="
        read -p "请输入操作编号: " opt

        case $opt in
            1)
                # 查看IP+检测可达性
                echo -e "\n===== 查看当前IP地址子菜单 ====="
                LOCAL_IP=$(hostname -I | awk '{print $1}')
                echo "Nginx IP地址: $LOCAL_IP"
                if check_ip_reachable $LOCAL_IP $NGINX_PORT; then
                    echo -e "Nginx可达性: ${GREEN}可用${NC}"
                else
                    echo -e "Nginx可达性: ${RED}不可用${NC}" | tee -a $LOG_FILE
                fi

                echo "Web-UI页面地址: $LOCAL_IP:$WEBUI_PORT"
                if check_ip_reachable $LOCAL_IP $WEBUI_PORT; then
                    echo -e "Web-UI可达性: ${GREEN}可用${NC}"
                else
                    echo -e "Web-UI可达性: ${RED}不可用${NC}" | tee -a $LOG_FILE
                fi

                # 读取转发配置中的地址（示例，需根据你的配置格式调整）
                echo -e "\n已转发地址列表:"
                if [ -f $NGINX_CONF_DIR/webui.conf ]; then
                    FORWARD_IPS=$(grep -E "proxy_pass|upstream" $NGINX_CONF_DIR/*.conf | awk '{print $2}' | grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | uniq)
                    idx=1
                    for ip in $FORWARD_IPS; do
                        echo "已转发地址$idx: $ip"
                        if check_ip_reachable $ip 80; then  # 假设转发端口为80，可自定义
                            echo -e "可达性: ${GREEN}可用${NC}"
                        else
                            echo -e "可达性: ${RED}不可用${NC}" | tee -a $LOG_FILE
                        fi
                        idx=$((idx+1))
                    done
                else
                    echo -e "${YELLOW}未检测到转发配置${NC}"
                fi
                ;;
            2)
                # 查看监听端口
                echo -e "\n===== 正在监听端口 ====="
                ss -tulpn | grep -E "nginx|python|node"  # 过滤Web相关进程的监听端口
                ;;
            3)
                # 查看异常日志
                echo -e "\n===== 异常日志 ====="
                tail -20 $LOG_FILE
                echo -e "\nNginx错误日志:"
                tail -20 /var/log/nginx/error.log
                ;;
            4)
                # 刷新配置
                echo -e "${YELLOW}正在刷新Nginx配置...${NC}"
                nginx -t > $LOG_FILE 2>&1
                if [ $? -eq 0 ]; then
                    systemctl reload nginx > $LOG_FILE 2>&1
                    echo -e "${GREEN}配置刷新成功${NC}"
                else
                    echo -e "${RED}配置语法错误，刷新失败！查看日志: $LOG_FILE${NC}" | tee -a $LOG_FILE
                fi
                ;;
            5)
                # 防火墙放行端口
                echo -e "${YELLOW}正在放行端口...${NC}"
                firewall_allow_port
                echo -e "${GREEN}端口放行完成${NC}"
                ;;
            q|Q)
                break
                ;;
            *)
                echo -e "${RED}无效输入${NC}" | tee -a $LOG_FILE
                ;;
        esac
    done
}

# ===================== 原主菜单（新增：初始化日志+预装最小化依赖） =====================
main_menu() {
    # 初始化日志（确保日志文件存在）
    touch $LOG_FILE
    chmod 644 $LOG_FILE

    # 预装全新系统最小化依赖（优先执行）
    install_minimal_deps

    while true; do
        echo -e "\n===== Nginx + Web环境 一键管理工具 ====="
        echo "1. 安装Nginx"
        echo "2. 安装Web-UI页面"
        echo "3. 安装Web-UI页面依赖"
        echo "4. 检查安装状态"
        echo "5. 查看运行状态"
        echo "6. 其他"
        echo "q. 退出"
        echo "====================================="
        read -p "请输入操作编号[1-6/q]: " opt

        case $opt in
            1)
                install_nginx
                ;;
            2)
                install_webui
                ;;
            3)
                install_deps
                ;;
            4)
                check_install_status
                ;;
            5)
                run_status_menu
                ;;
            6)
                other_menu
                ;;
            q|Q)
                echo -e "${YELLOW}退出脚本...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效输入，请输入1-6或q${NC}" | tee -a $LOG_FILE
                ;;
        esac
    done
}

# 启动脚本
check_os
main_menu