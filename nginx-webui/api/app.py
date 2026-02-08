from flask import Flask, render_template, request, jsonify
import subprocess
import os
import shutil

app = Flask(__name__, 
            template_folder='../templates', 
            static_folder='../static')

# 屏蔽高危路径/操作（核心保护）
HIGH_RISK_PATHS = ['/etc/nginx/nginx.conf'[:-5], '/usr/sbin/nginx', '/boot', '/root']
HIGH_RISK_COMMANDS = ['rm -rf /', 'mv /', 'chmod 777 /']

# 1. 基础：获取Nginx状态
@app.route('/api/nginx/status')
def nginx_status():
    try:
        # 封装nginx -s status命令（大白话返回）
        result = subprocess.run(['systemctl', 'status', 'nginx'], capture_output=True, text=True)
        if 'active (running)' in result.stdout:
            pid = subprocess.run(['pgrep', 'nginx'], capture_output=True, text=True).stdout.strip().split('\n')[0]
            return jsonify({'status': 'running', 'pid': pid, 'msg': 'Nginx正在正常运行'})
        else:
            return jsonify({'status': 'stopped', 'msg': 'Nginx已停止运行'})
    except Exception as e:
        return jsonify({'status': 'error', 'msg': f'查看状态失败：{str(e)}（大白话：可能是Nginx没装或命令错了）'})

# 2. 站点管理：添加站点（示例，简化版）
@app.route('/api/site/add', methods=['POST'])
def add_site():
    try:
        # 获取前端参数（大白话命名，避免专业术语）
        site_name = request.form.get('site_name')
        domain = request.form.get('domain')
        port = request.form.get('port', 80)
        root_dir = request.form.get('root_dir', '/var/www/html')

        # 校验参数（大白话提示）
        if not site_name:
            return jsonify({'code': 1, 'msg': '请填写网站名称（比如：我的博客）'})
        if not domain and port == '80':
            return jsonify({'code': 1, 'msg': '80端口需要填写域名（比如：www.xxx.com）'})

        # 生成站点配置文件（不修改核心配置，仅添加conf.d文件）
        conf_path = f'/etc/nginx/conf.d/{site_name}.conf'
        conf_content = f"""
server {{
    listen {port};
    server_name {domain};
    root {root_dir};
    index index.html index.htm;

    # 自动补全最优参数（零基础友好）
    client_max_body_size 10M;
    proxy_connect_timeout 60s;
    proxy_read_timeout 60s;
}}
"""
        # 写入配置文件
        with open(conf_path, 'w', encoding='utf-8') as f:
            f.write(conf_content)

        # 校验配置（大白话提示错误）
        check_result = subprocess.run(['nginx', '-t'], capture_output=True, text=True)
        if 'test is successful' in check_result.stderr:
            # 重载配置
            subprocess.run(['nginx', '-s', 'reload'], capture_output=True)
            return jsonify({'code': 0, 'msg': f'网站添加成功！已自动生效（配置文件：{conf_path}）'})
        else:
            # 删除错误配置，避免影响Nginx
            os.remove(conf_path)
            return jsonify({'code': 1, 'msg': f'配置错误：{check_result.stderr}（大白话：可能是端口被占用或域名格式错了）'})
    except Exception as e:
        return jsonify({'code': 1, 'msg': f'添加失败：{str(e)}（大白话：检查路径是否存在或权限够不够）'})

# 3. 文件管理（过滤高危路径）
@app.route('/api/file/list')
def list_files():
    try:
        path = request.args.get('path', '/etc/nginx')
        # 校验路径是否高危
        if any(path.startswith(risk) for risk in HIGH_RISK_PATHS):
            return jsonify({'code': 1, 'msg': '该路径是高危文件，禁止访问（大白话：改这个会导致服务器崩溃）'})
        # 列出文件
        files = []
        for f in os.listdir(path):
            f_path = os.path.join(path, f)
            files.append({
                'name': f,
                'type': 'dir' if os.path.isdir(f_path) else 'file',
                'size': os.path.getsize(f_path) if os.path.isfile(f_path) else '-',
                'mtime': os.path.getmtime(f_path)
            })
        return jsonify({'code': 0, 'data': files})
    except Exception as e:
        return jsonify({'code': 1, 'msg': f'查看文件失败：{str(e)}（大白话：检查路径是否存在或权限够不够）'})

# ========== 新增：所有页面的访问路由（核心修复） ==========
# 首页路由（原有，保留）
@app.route('/')
def index():
    return render_template('index.html')

# 我的网站页面路由
@app.route('/site')
def site():
    return render_template('site.html')

# 反向代理页面路由
@app.route('/proxy')
def proxy():
    return render_template('proxy.html')

# SSL证书页面路由
@app.route('/ssl')
def ssl():
    return render_template('ssl.html')

# 文件管理页面路由
@app.route('/file')
def file():
    return render_template('file.html')

# 配置备份页面路由
@app.route('/backup')
def backup():
    return render_template('backup.html')

# 服务操作页面路由
@app.route('/service')
def service():
    status_data = nginx_status().json
    return render_template('service.html', status=status_data)

# 日志管理页面路由
@app.route('/log')
def log():
    return render_template('log.html')
# ========== 新增结束 ==========

if __name__ == '__main__':
    # 仅监听本地+指定端口，轻量化运行（debug=True方便调试，上线后改回False）
    app.run(host='0.0.0.0', port=8888, debug=True)