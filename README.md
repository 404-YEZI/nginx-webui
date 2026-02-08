# Nginx WebUI - 零基础Nginx可视化管理工具
[![Nginx 1.28](https://img.shields.io/badge/Nginx-stable--1.28-009639?style=flat-square)](https://nginx.org/)
[![Debian 12/11](https://img.shields.io/badge/Debian-12%2F11-A81D33?style=flat-square)]()
[![Ubuntu 20.04+/22.04](https://img.shields.io/badge/Ubuntu-20.04%2B%2F22.04-E95420?style=flat-square)]()
[![License: Nginx BSD](https://img.shields.io/badge/License-Nginx%20BSD-000000?style=flat-square)]()
[![Project Size](https://img.shields.io/badge/Size-<10MB-green?style=flat-square)]()
[![Python 3.8+](https://img.shields.io/badge/Python-3.8+-3776AB?style=flat-square&logo=python)](https://www.python.org/)

> 🔗 基于Nginx官方仓库开发：[nginx/nginx](https://github.com/nginx/nginx)  
> 🔥 解决痛点：新手不会写Nginx配置、命令行操作易出错、SSL证书申请/续期繁琐、配置出错难排查  
> ✨ 核心优势：零基础可视化操作 | 100%兼容Nginx官方功能 | 轻量化无冗余依赖 | 配置自动校验防崩溃  
> 🎯 适用人群：运维新手、个人站长、中小企业管理员，5分钟即可完成网站/反向代理/HTTPS搭建！

## 快速开始
### 前提条件
- 服务器需为 `root` 权限（普通用户需加 `sudo` 执行命令）
- 服务器可联网（需拉取Nginx安装包、依赖及SSL证书）
- 放行端口：80（HTTP）、443（HTTPS）、8888（WebUI管理端口）

### 一键安装（推荐，Debian/Ubuntu通用）
```bash
# 一键安装（自动适配系统、安装依赖、配置Nginx、启动WebUI）
curl -sSL https://raw.githubusercontent.com/404-YEZI/nginx-webui/nginx/install.sh | bash
```

#### 安装常见问题处理
- 若提示 `curl: command not found`：先安装curl → `apt update && apt install curl -y`
- 若安装卡住：检查服务器网络（可尝试切换国内源），或手动克隆仓库安装（见「手动部署」）
- 若提示权限不足：切换root用户 → `sudo -i` 后重新执行安装命令

### 访问与初始配置
1. 安装完成后，终端会输出如下提示（示例）：
   ```
   ✅ Nginx WebUI 安装成功！
   📌 访问地址：http://你的服务器IP:8888
   🔑 初始账号：admin | 初始密码：123456（首次登录请立即修改！）
   📝 配置文件路径：/etc/nginx/conf.d/
   🗃️ 备份文件路径：/opt/nginx-webui/data/backup/
   ```
2. 查看服务器公网IP：`curl ifconfig.me`（或内网IP：`hostname -I`）
3. 浏览器访问 `http://服务器IP:8888`，输入初始账号密码登录
4. 首次登录强制修改密码，完成后即可开始可视化配置Nginx

#### 访问失败排查
- 检查8888端口是否放行：`ufw allow 8888/tcp`（Debian/Ubuntu）
- 检查WebUI服务是否运行：`ps aux | grep nginx-webui`
- 检查Nginx是否启动：`systemctl status nginx`
- 查看WebUI日志：`cat /opt/nginx-webui/data/logs/webui.log`

## 项目介绍
本工具基于 **Nginx官方stable-1.28稳定分支** 开发，未修改任何Nginx核心源码，仅通过「可视化Web界面+辅助脚本」实现配置自动化，核心特性如下：

### 技术栈（轻量化无冗余）
- 后端：Python 3.8+ + Flask（仅核心依赖，无复杂框架）
- 前端：Tailwind CSS + Vanilla JS（无Vue/React，加载速度快）
- 数据存储：本地文件（无数据库，无需额外部署MySQL/Redis）
- 整体体积：核心文件<10MB，依赖安装后总占用<50MB

### 核心价值
- 告别命令行：所有操作通过「卡片式UI+点击选择」完成，无需手写`nginx.conf`
- 配置防错：内置配置校验规则，非法参数、端口冲突、路径错误会实时提示
- 安全兜底：过滤高危配置（如访问系统根目录），自动备份配置，可一键回滚
- 成本极低：无需服务器额外资源，兼容低配服务器（1核1G即可运行）

## 核心功能（详细说明）
| 功能模块       | 核心能力                                                                 | 细节补充                                                                 |
|----------------|--------------------------------------------------------------------------|--------------------------------------------------------------------------|
| 📌 站点管理    | 增/删/改站点，配置域名、端口、根目录，自动补全最优参数                   | 支持多域名绑定、端口自定义（1-65535）、根目录权限自动适配；删除站点自动清理配置文件 |
| 🚀 反向代理    | 独立配置每个代理，可视化填写目标地址/请求头/超时时间，支持多规则并行     | 支持HTTP/HTTPS代理、自定义请求头（如User-Agent、Referer）、超时时间（1-300s）配置 |
| 🔒 SSL证书     | 一键申请Let's Encrypt免费证书（自动续期）+ 手动上传自有证书（.crt/.key） | 1）Let's Encrypt证书：自动续期（每60天），支持多域名；2）手动上传：仅支持PEM格式，自动校验证书有效性 |
| 📁 文件管理    | 安全操作Nginx非高危文件，支持上传/下载/删除/查看，屏蔽系统核心文件       | 仅允许操作`/etc/nginx/`下非核心文件，禁止修改`nginx.conf`主配置；支持批量上传静态文件（如网站源码） |
| 📦 配置备份    | 自动按时间戳备份配置，支持一键回滚，保留30天备份记录                     | 自动备份触发时机：修改配置、重启Nginx；手动备份可自定义备注；回滚后自动重载Nginx |
| ⚙️ 服务操作    | 校验配置、重载/重启/停止Nginx，实时查看运行状态（PID/版本）              | 配置校验：模拟Nginx启动检测语法错误；重载Nginx无停机，不影响现有服务       |
| 📜 日志管理    | 切换访问/错误日志，按行数/关键词筛选，支持下载，大白话解释日志含义       | 日志筛选：支持按「最近100行/500行/全部」或「关键词（如404/502）」过滤；日志解释：自动标注常见错误原因（如502=后端服务未启动） |

> 📸 功能截图（替换为实际截图链接）：
> - 首页（运行状态+快捷操作）：![首页截图](https://xxx.com/nginx-webui-index.png)
> - 站点配置（可视化表单）：![站点配置截图](https://xxx.com/nginx-webui-site.png)
> - SSL证书申请（一键操作）：![SSL配置截图](https://xxx.com/nginx-webui-ssl.png)
> - 日志筛选（关键词过滤）：![日志管理截图](https://xxx.com/nginx-webui-log.png)

## 部署方式（详细步骤）
### 1. 一键安装（推荐，新手首选）
#### 安装命令
```bash
# 切换root用户（避免权限问题）
sudo -i
# 执行一键安装
curl -sSL https://raw.githubusercontent.com/404-YEZI/nginx-webui/nginx/install.sh | bash
```

#### 卸载/重置
```bash
# 一键卸载（保留配置备份）
curl -sSL https://raw.githubusercontent.com/404-YEZI/nginx-webui/nginx/uninstall.sh | bash
# 重置WebUI（恢复初始配置，保留Nginx）
curl -sSL https://raw.githubusercontent.com/404-YEZI/nginx-webui/nginx/reset.sh | bash
```

### 2. Docker部署（隔离性强，推荐有Docker基础用户）
#### 前提：安装Docker
```bash
# Debian/Ubuntu安装Docker
apt update && apt install docker.io -y
# 启动Docker并设置开机自启
systemctl start docker && systemctl enable docker
```

#### 启动容器
```bash
docker run -d \
  --name nginx-webui \
  # 映射端口：宿主机8888→容器8888（WebUI），80→80（HTTP），443→443（HTTPS）
  -p 8888:8888 \
  -p 80:80 \
  -p 443:443 \
  # 挂载目录：宿主机配置→容器配置（持久化）
  -v /etc/nginx/conf.d:/etc/nginx/conf.d \
  -v /opt/nginx-webui/data:/opt/nginx-webui/data \
  # 挂载日志目录（可选）
  -v /var/log/nginx:/var/log/nginx \
  # 赋予容器权限（需修改Nginx配置）
  --privileged=true \
  # 镜像地址（替换为实际镜像名）
  404yezi/nginx-webui:latest
```

#### Docker常用操作
```bash
# 查看容器运行状态
docker ps | grep nginx-webui
# 查看容器日志
docker logs nginx-webui
# 重启容器
docker restart nginx-webui
# 删除容器（需先停止）
docker stop nginx-webui && docker rm nginx-webui
```

### 3. 手动部署（开发者/自定义需求）
#### 前提：安装依赖
```bash
# 更新源并安装基础依赖
apt update && apt install -y python3 python3-pip git nginx
# 安装Flask（WebUI后端核心）
pip3 install flask
```

#### 部署步骤
```bash
# 1. 克隆仓库到指定目录
git clone -b nginx https://github.com/404-YEZI/nginx-webui.git /opt/nginx-webui

# 2. 赋予脚本执行权限
cd /opt/nginx-webui && chmod +x run.py scripts/*.sh

# 3. 修改Nginx主配置（允许加载conf.d目录）
# 确认/etc/nginx/nginx.conf中包含：include /etc/nginx/conf.d/*.conf;

# 4. 启动WebUI服务（后台运行）
nohup python3 /opt/nginx-webui/run.py > /opt/nginx-webui/data/logs/webui.log 2>&1 &

# 5. 设置开机自启（可选）
echo "nohup python3 /opt/nginx-webui/run.py > /opt/nginx-webui/data/logs/webui.log 2>&1 &" >> /etc/rc.local
chmod +x /etc/rc.local
```

## 环境要求（详细）
| 类型         | 具体要求                                                                 | 备注                                   |
|--------------|--------------------------------------------------------------------------|----------------------------------------|
| 系统         | Debian 11/12、Ubuntu 20.04/22.04（推荐）；CentOS 7/8（兼容，需调整脚本） | 其他系统需手动适配依赖安装命令         |
| 权限         | root（或sudo权限）                                                       | 非root用户需在命令前加`sudo`           |
| 网络         | 可访问外网（GitHub、Nginx官网、Let's Encrypt）                           | 内网服务器需配置代理                   |
| 依赖         | Python 3.8+、curl、wget、nginx（一键安装会自动安装）                     | Python版本过低需手动升级（`apt install python3.9`） |
| 端口         | 80、443、8888未被占用                                                   | 端口被占用可修改`/opt/nginx-webui/config.py`调整WebUI端口 |

## 项目结构（详细说明）
```
nginx-webui/
├── run.py              # WebUI主启动文件（Flask入口，监听8888端口）
├── install.sh          # 一键安装脚本（适配系统、安装依赖、配置自启）
├── uninstall.sh        # 一键卸载脚本（停止服务、清理文件，保留备份）
├── reset.sh            # 重置脚本（恢复初始配置，保留Nginx核心）
├── README.md           # 项目说明文档（当前文件）
├── LICENSE             # 版权声明（BSD 2-Clause）
├── .gitignore          # Git忽略规则（系统垃圾、运行时文件、敏感数据）
├── config.py           # WebUI核心配置（端口、账号、备份路径等，可自定义）
├── api/                # Flask后端接口目录
│   ├── site_api.py     # 站点管理接口（增删改查、配置生成）
│   ├── ssl_api.py      # SSL证书接口（申请、续期、上传、校验）
│   ├── proxy_api.py    # 反向代理接口（规则配置、参数校验）
│   ├── log_api.py      # 日志管理接口（读取、筛选、下载日志）
│   └── system_api.py   # 系统操作接口（Nginx启停、配置校验、备份回滚）
├── scripts/            # 辅助脚本目录
│   ├── ssl_auto.sh     # SSL证书自动续期脚本（每日定时执行）
│   ├── backup.sh       # 配置备份脚本（自动/手动触发）
│   ├── nginx_ops.sh    # Nginx操作脚本（启停、重载、校验）
│   └── check_dep.sh    # 依赖检查脚本（安装前自动执行）
├── static/             # 前端静态资源（JS/CSS/图片）
│   ├── js/             # 交互逻辑JS（表单提交、数据渲染、实时校验）
│   ├── css/            # 样式文件（Tailwind CSS压缩版，轻量化）
│   └── img/            # 页面图片（logo、图标等）
├── templates/          # 前端页面模板（Jinja2）
│   ├── index.html      # 首页（运行状态、快捷操作、功能入口）
│   ├── site.html       # 站点管理页面（增删改查、参数配置）
│   ├── proxy.html      # 反向代理配置页面
│   ├── ssl.html        # SSL证书管理页面
│   ├── file.html       # 文件管理页面
│   ├── backup.html     # 配置备份页面
│   ├── service.html    # Nginx服务操作页面
│   └── log.html        # 日志管理页面
└── data/               # 动态数据目录（自动生成，持久化存储）
    ├── logs/           # 日志目录（WebUI运行日志、操作日志）
    ├── backup/         # 配置备份目录（按时间戳命名，保留30天）
    ├── ssl/            # SSL证书目录（Let's Encrypt证书、手动上传证书）
    └── user.db         # 用户数据文件（账号密码，加密存储）
```

## 常见问题（FAQ）
### Q1：访问WebUI提示「无法连接」？
- 检查8888端口是否放行：`ufw allow 8888/tcp`（Debian/Ubuntu）；CentOS用`firewall-cmd --add-port=8888/tcp --permanent && firewall-cmd --reload`
- 检查WebUI是否运行：`ps aux | grep run.py`，未运行则执行`python3 /opt/nginx-webui/run.py`
- 检查服务器防火墙/安全组（阿里云/腾讯云等需在控制台放行8888端口）

### Q2：配置站点后无法访问？
- 检查80/443端口是否放行；
- 检查Nginx配置是否生效：`nginx -t`（校验配置）→ `systemctl reload nginx`（重载配置）；
- 检查站点根目录是否存在且权限正确：`chmod -R 755 /网站根目录`；
- 查看错误日志：WebUI→日志管理→错误日志，筛选关键词排查。

### Q3：SSL证书申请失败？
- 检查80端口是否未被占用（Let's Encrypt验证需80端口）；
- 检查域名是否解析到服务器公网IP；
- 检查服务器网络是否能访问Let's Encrypt（`curl https://acme-v02.api.letsencrypt.org/`）；
- 域名已被封禁：更换域名或手动上传自有证书。

### Q4：WebUI密码忘记了？
- 执行重置密码脚本：`bash /opt/nginx-webui/scripts/reset_pwd.sh`（初始密码恢复为123456）；
- 或手动修改`/opt/nginx-webui/data/user.db`（需Python脚本解密，推荐用重置脚本）。

### Q5：配置修改后不生效？
- 确认点击了「保存并重载Nginx」按钮；
- 检查配置是否有语法错误（WebUI会提示，或执行`nginx -t`）；
- 重载Nginx：`systemctl reload nginx`（手动触发）。

## 注意事项（重要）
1. **安全防护**：
   - 首次登录务必修改初始密码，避免弱密码被破解；
   - 建议仅对内网/指定IP开放8888端口（可在防火墙设置IP白名单）；
   - 不要在WebUI中修改Nginx主配置（`/etc/nginx/nginx.conf`），仅通过conf.d目录管理站点。

2. **数据备份**：
   - 重要配置建议手动下载备份（WebUI→配置备份→下载）；
   - 定期备份`/opt/nginx-webui/data`目录，避免数据丢失。

3. **版本更新**：
   - 升级前先备份配置：`bash /opt/nginx-webui/scripts/backup.sh`；
   - 执行更新脚本：`git pull`（手动部署）或重新执行一键安装脚本（保留配置）。

4. **禁止操作**：
   - 不要删除`/opt/nginx-webui/data`目录（包含备份、证书、日志）；
   - 不要修改Nginx核心源码（会导致兼容性问题）。

## 贡献指南
### 贡献方向
- 功能优化：新增可视化功能（如负载均衡配置、防盗链配置）；
- 兼容性适配：适配CentOS、Fedora等系统；
- Bug修复：解决已知问题、优化用户体验；
- 文档完善：补充使用教程、翻译多语言文档。

### 贡献步骤
1. Fork本仓库到你的GitHub账号；
2. 创建特性分支：`git checkout -b feature/xxx`（xxx为功能名，如`feature/load_balance`）；
3. 提交修改：遵循「轻量化、无核心修改」原则，代码注释清晰；
4. 测试验证：在本地/测试服务器验证功能正常，无兼容性问题；
5. 提交PR：描述修改内容、测试环境、功能亮点，等待审核合并。

## 问题反馈
### 反馈渠道
- GitHub Issue：[https://github.com/404-YEZI/nginx-webui/issues](https://github.com/404-YEZI/nginx-webui/issues)（优先）
- 邮件反馈：xxx@yezi.com（替换为实际邮箱）

### 反馈模板（建议）
```
【问题类型】：功能故障/使用疑问/功能建议
【系统版本】：Debian 12（举例）
【操作步骤】：1. 点击站点管理→新增站点；2. 填写域名xxx.com；3. 保存后提示错误
【问题现象】：页面提示「配置校验失败」，Nginx日志显示xxx错误
【截图/日志】：（粘贴截图链接或日志内容）
【其他信息】：服务器配置1核1G，80端口已放行
```

## 版权声明
```
Copyright (C) 2002-2021 Igor Sysoev
Copyright (C) 2011-2026 Nginx, Inc.
Copyright (C) 2026 YEZI

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

## 特别修改说明
本项目基于Nginx官方开源代码构建，YEZI仅针对零基础用户开发了可视化Web管理页面（无任何Nginx核心逻辑修改），
旨在降低Nginx配置门槛，让非专业用户可通过点击操作完成站点/代理/SSL等配置。
本修改不改变Nginx核心代码的版权归属，核心版权仍归Igor Sysoev和Nginx, Inc.所有。

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
```

## 致谢
- Nginx官方团队：提供高性能、稳定的核心Web服务器；
- Let's Encrypt：提供免费SSL证书，降低HTTPS使用门槛；
- Tailwind CSS：轻量化CSS框架，让前端开发更高效；
- 所有贡献者：感谢提交Bug、优化功能、完善文档的开发者。
