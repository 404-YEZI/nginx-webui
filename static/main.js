// 全局配置
const API_BASE = '';
// 消息提示（大白话友好提示，右上角浮动）
function showMsg(msg, isError = false) {
    const msgBox = document.createElement('div');
    msgBox.style.position = 'fixed';
    msgBox.style.top = '20px';
    msgBox.style.right = '20px';
    msgBox.style.padding = '15px 20px';
    msgBox.style.borderRadius = '8px';
    msgBox.style.zIndex = '9999';
    msgBox.style.boxShadow = '0 2px 10px rgba(0,0,0,0.1)';
    msgBox.style.color = '#fff';
    msgBox.style.backgroundColor = isError ? '#dc2626' : '#16a34a';
    msgBox.style.transition = 'opacity 0.5s ease';
    msgBox.innerText = msg;
    document.body.appendChild(msgBox);
    // 3秒后自动消失
    setTimeout(() => {
        msgBox.style.opacity = '0';
        setTimeout(() => document.body.removeChild(msgBox), 500);
    }, 3000);
}

// 发起AJAX请求（POST/GET，适配FormData/普通参数）
function ajax(url, method = 'GET', data = {}, callback) {
    const xhr = new XMLHttpRequest();
    xhr.open(method, API_BASE + url, true);
    // 跨域/请求头配置
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    if (method === 'POST' && !(data instanceof FormData)) {
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        const formData = new URLSearchParams(data);
        xhr.send(formData);
    } else {
        if (method === 'GET' && Object.keys(data).length > 0) {
            const params = new URLSearchParams(data);
            url += '?' + params.toString();
            xhr.open(method, API_BASE + url, true);
        }
        xhr.send(data instanceof FormData ? data : null);
    }
    // 响应处理
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
            try {
                const res = JSON.parse(xhr.responseText);
                callback(res);
            } catch (e) {
                callback({code: 1, msg: '请求失败：网络异常或服务器错误'});
            }
        }
    };
    // 网络错误处理
    xhr.onerror = function() {
        callback({code: 1, msg: '请求失败：无法连接到服务器'});
    };
}

// 前端路径处理：获取上级目录（替代node的os.path.dirname，浏览器端可用）
function getParentPath(path) {
    path = path.replace(/\/$/, '');
    const lastSlash = path.lastIndexOf('/');
    return lastSlash === -1 ? '/' : path.substring(0, lastSlash);
}

// 页面加载完成后初始化所有交互
document.addEventListener('DOMContentLoaded', function() {
    // 1. 导航高亮（匹配当前页面路径）
    const currentHref = window.location.pathname;
    document.querySelectorAll('.nav-item').forEach(item => {
        const itemHref = item.getAttribute('data-href') || '#';
        if (currentHref === itemHref) {
            item.classList.add('active');
        }
        // 导航点击跳转
        item.addEventListener('click', function() {
            window.location.href = itemHref;
        });
    });

    // 2. Nginx配置校验按钮通用逻辑
    const checkBtn = document.getElementById('nginx-check');
    if (checkBtn) {
        checkBtn.addEventListener('click', function() {
            this.disabled = true;
            this.innerText = '校验中...';
            ajax('/api/nginx/check', 'GET', {}, function(res) {
                checkBtn.disabled = false;
                checkBtn.innerText = '校验Nginx配置';
                showMsg(res.msg, res.code !== 0);
            });
        });
    }

    // 3. Nginx服务操作按钮（reload/restart/stop/start）通用逻辑
    document.querySelectorAll('.nginx-op').forEach(btn => {
        btn.addEventListener('click', function() {
            const op = this.getAttribute('data-op');
            const opText = this.getAttribute('data-text');
            if (!op) return;
            this.disabled = true;
            this.innerText = '操作中...';
            ajax('/api/nginx/operate', 'POST', {op: op}, function(res) {
                btn.disabled = false;
                btn.innerText = opText;
                showMsg(res.msg, res.code !== 0);
                // 操作成功后刷新状态页面
                if (res.code === 0 && window.location.pathname === '/service') {
                    window.location.reload();
                }
            });
        });
    });

    // 4. 手动备份配置按钮逻辑
    const backupCreateBtn = document.getElementById('backup-create');
    if (backupCreateBtn) {
        backupCreateBtn.addEventListener('click', function() {
            this.disabled = true;
            this.innerText = '备份中...';
            ajax('/api/backup/create', 'GET', {}, function(res) {
                backupCreateBtn.disabled = false;
                backupCreateBtn.innerText = '手动备份配置';
                showMsg(res.msg, res.code !== 0);
                // 备份成功后刷新备份列表
                if (res.code === 0 && window.location.pathname === '/backup') {
                    window.location.reload();
                }
            });
        });
    }

    // 5. 配置回滚按钮通用逻辑
    document.querySelectorAll('.backup-restore').forEach(btn => {
        btn.addEventListener('click', function() {
            const backupFile = this.getAttribute('data-file');
            if (!backupFile) return;
            // 二次确认，防止误操作
            if (!confirm('⚠️ 确定要回滚到此备份吗？\n回滚前会自动备份当前配置，操作后配置将覆盖！')) return;
            this.disabled = true;
            this.innerText = '回滚中...';
            ajax('/api/backup/restore', 'POST', {backup_file: backupFile}, function(res) {
                btn.disabled = false;
                btn.innerText = '回滚';
                showMsg(res.msg, res.code !== 0);
                if (res.code === 0) {
                    window.location.reload();
                }
            });
        });
    });

    // 6. 站点删除按钮通用逻辑
    document.querySelectorAll('.site-delete').forEach(btn => {
        btn.addEventListener('click', function() {
            const siteFile = this.getAttribute('data-file');
            if (!siteFile) return;
            if (!confirm('⚠️ 确定要删除该站点吗？\n删除后配置文件将永久移除！')) return;
            ajax('/api/site/delete', 'POST', {site_file: siteFile}, function(res) {
                showMsg(res.msg, res.code !== 0);
                if (res.code === 0 && window.location.pathname === '/site') {
                    loadSiteList(); // 刷新站点列表
                }
            });
        });
    });

    // 7. 文件删除按钮通用逻辑
    document.querySelectorAll('.file-delete').forEach(btn => {
        btn.addEventListener('click', function() {
            const path = this.getAttribute('data-path');
            if (!path) return;
            if (!confirm('⚠️ 确定要删除吗？\n删除后无法恢复！')) return;
            ajax('/api/file/delete', 'POST', {path: path}, function(res) {
                showMsg(res.msg, res.code !== 0);
                if (res.code === 0 && window.location.pathname === '/file') {
                    // 刷新当前文件列表（获取当前路径）
                    const currentPath = document.getElementById('current-path').getAttribute('data-path');
                    loadFileList(currentPath);
                }
            });
        });
    });

    // 8. 通用表单提交逻辑（站点/代理/SSL申请）
    document.querySelectorAll('.form-submit').forEach(btn => {
        btn.addEventListener('click', function() {
            const form = this.closest('form');
            const apiUrl = form.getAttribute('data-api');
            if (!form || !apiUrl) return;
            // 简单表单校验：必填项标红的不能为空
            const requiredInputs = form.querySelectorAll('input[required], textarea[required]');
            let isFormValid = true;
            requiredInputs.forEach(input => {
                if (!input.value.trim()) {
                    isFormValid = false;
                    input.style.border = '1px solid #dc2626';
                    // 失去焦点后恢复边框
                    input.addEventListener('blur', function() {
                        this.style.border = '1px solid #d1d5db';
                    });
                }
            });
            if (!isFormValid) {
                showMsg('大白话：标红的必填项不能为空！', true);
                return;
            }
            // 提交表单
            const formData = new FormData(form);
            this.disabled = true;
            this.innerText = '保存中...';
            ajax(apiUrl, 'POST', formData, function(res) {
                btn.disabled = false;
                btn.innerText = '保存配置';
                showMsg(res.msg, res.code !== 0);
                // 保存成功后重置表单
                if (res.code === 0) {
                    form.reset();
                    // 刷新对应列表
                    if (apiUrl === '/api/site/save' && window.location.pathname === '/site') {
                        loadSiteList();
                    }
                }
            });
        });
    });

    // 9. 文件上传表单通用逻辑
    document.querySelectorAll('.file-upload-form').forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault(); // 阻止默认提交
            const apiUrl = this.getAttribute('data-api');
            const btn = this.querySelector('.upload-btn');
            const fileInput = this.querySelector('input[type="file"]');
            if (!apiUrl || !btn || !fileInput.files.length) {
                showMsg('大白话：请选择要上传的文件！', true);
                return;
            }
            // 提交上传
            const formData = new FormData(this);
            btn.disabled = true;
            btn.innerText = '上传中...';
            ajax(apiUrl, 'POST', formData, function(res) {
                btn.disabled = false;
                btn.innerText = '上传文件';
                showMsg(res.msg, res.code !== 0);
                if (res.code === 0 && window.location.pathname === '/file') {
                    const currentPath = document.getElementById('current-path').getAttribute('data-path');
                    loadFileList(currentPath);
                }
            });
        });
    });

    // 10. 日志筛选按钮逻辑
    const logFilterBtn = document.getElementById('log-filter');
    if (logFilterBtn) {
        logFilterBtn.addEventListener('click', function() {
            const logType = document.getElementById('log-type').value;
            const lines = document.getElementById('log-lines').value;
            const keyword = document.getElementById('log-keyword').value.trim();
            // 校验行数
            if (!/^\d+$/.test(lines) || lines < 10 || lines > 1000) {
                showMsg('大白话：日志行数请填写10-1000的数字！', true);
                return;
            }
            loadLog(logType, lines, keyword);
        });
        // 日志回车筛选
        document.getElementById('log-keyword').addEventListener('keydown', function(e) {
            if (e.key === 'Enter') logFilterBtn.click();
        });
    }

    // 页面初始化执行对应方法
    if (window.location.pathname === '/log') {
        loadLog('access', 100, ''); // 初始化加载访问日志
    }
    if (window.location.pathname === '/site') {
        loadSiteList(); // 初始化加载站点列表
    }
    if (window.location.pathname === '/file') {
        const defaultPath = '/etc/nginx/conf.d';
        loadFileList(defaultPath); // 初始化加载默认文件路径
    }
});

// 加载站点列表（独立方法，支持刷新）
function loadSiteList() {
    const siteTable = document.getElementById('site-table');
    if (!siteTable) return;
    const tbody = siteTable.querySelector('tbody');
    tbody.innerHTML = '<tr><td colspan="5" class="p-3 text-center text-gray-500">加载中...</td></tr>';
    // 调用后端API
    ajax('/api/site/list', 'GET', {}, function(res) {
        if (res.code !== 0) {
            tbody.innerHTML = `<tr><td colspan="5" class="p-3 text-center text-red-500">${res.msg}</td></tr>`;
            showMsg(res.msg, true);
            return;
        }
        // 渲染空列表
        if (res.data.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="p-3 text-center text-gray-500">暂无站点，点击上方「添加网站」创建</td></tr>';
            return;
        }
        // 渲染站点列表
        tbody.innerHTML = '';
        res.data.forEach(site => {
            const tr = document.createElement('tr');
            tr.className = 'border-t hover:bg-gray-50';
            tr.innerHTML = `
                <td class="p-3">${site.name || '未知名称'}</td>
                <td class="p-3">${site.domain || '无域名'}</td>
                <td class="p-3 font-medium">${site.port}</td>
                <td class="p-3">${site.https ? '<span class="text-green-500">✅ 已开启</span>' : '<span class="text-red-500">❌ 未开启</span>'}</td>
                <td class="p-3">
                    <span class="text-blue-600 hover:underline mr-3 cursor-pointer" onclick="editSite('${site.file}')">编辑</span>
                    <span class="text-red-600 hover:underline site-delete cursor-pointer" data-file="${site.file}">删除</span>
                </td>
            `;
            tbody.appendChild(tr);
        });
        // 重新绑定删除事件（动态渲染后）
        document.querySelectorAll('.site-delete').forEach(btn => {
            btn.addEventListener('click', function() {
                const siteFile = this.getAttribute('data-file');
                if (!siteFile) return;
                if (!confirm('⚠️ 确定要删除该站点吗？\n删除后配置文件将永久移除！')) return;
                ajax('/api/site/delete', 'POST', {site_file: siteFile}, function(res) {
                    showMsg(res.msg, res.code !== 0);
                    if (res.code === 0) loadSiteList();
                });
            });
        });
    });
}

// 编辑站点（预留方法，可扩展）
function editSite(siteFile) {
    showMsg('编辑功能暂未开放，敬请期待！', false);
    // 后续可扩展：根据siteFile获取配置，填充到表单
}

// 加载日志内容（独立方法，支持筛选/刷新）
function loadLog(logType = 'access', lines = 100, keyword = '') {
    const logContent = document.getElementById('log-content');
    const logDownload = document.getElementById('log-download');
    if (!logContent) return;
    // 初始化加载状态
    logContent.innerText = '正在加载日志...';
    logContent.style.color = '#6b7280';
    // 更新下载链接
    if (logDownload) {
        logDownload.href = `/api/log/download?log_type=${logType}`;
        logDownload.innerText = `下载${logType === 'access' ? '访问' : '错误'}日志`;
    }
    // 调用后端API
    ajax('/api/log/get', 'GET', {
        log_type: logType,
        lines: lines,
        keyword: keyword
    }, function(res) {
        if (res.code !== 0) {
            logContent.innerText = res.msg;
            logContent.style.color = '#dc2626';
            showMsg(res.msg, true);
            return;
        }
        // 渲染日志内容
        logContent.innerText = res.data || '暂无日志内容';
        logContent.style.color = '#111827';
        // 自动滚动到日志底部
        logContent.scrollTop = logContent.scrollHeight;
    });
}

// 加载文件列表（独立方法，支持目录跳转/刷新）
function loadFileList(path) {
    const fileList = document.getElementById('file-list');
    const currentPathEl = document.getElementById('current-path');
    const uploadPathInput = document.querySelector('input[name="path"]');
    if (!fileList || !currentPathEl) return;
    // 初始化加载状态
    fileList.innerHTML = '<div class="p-3 text-center text-gray-500">正在加载文件...</div>';
    // 更新当前路径
    currentPathEl.innerText = path;
    currentPathEl.setAttribute('data-path', path);
    // 更新上传表单的路径
    if (uploadPathInput) uploadPathInput.value = path;
    // 调用后端API
    ajax('/api/file/list', 'GET', {path: path}, function(res) {
        if (res.code !== 0) {
            fileList.innerHTML = `<div class="p-3 text-center text-red-500">${res.msg}</div>`;
            showMsg(res.msg, true);
            return;
        }
        // 渲染文件列表
        let html = '';
        // 添加上级目录（根目录除外）
        if (path !== '/') {
            const parentPath = getParentPath(path);
            html += `
                <div class="file-item flex items-center p-2 hover:bg-gray-50 rounded-lg cursor-pointer transition-colors" onclick="loadFileList('${parentPath}')">
                    <svg class="w-5 h-5 mr-2 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                    </svg>
                    <span class="font-medium">../ 上级目录</span>
                </div>
            `;
        }
        // 渲染空目录
        if (res.data.length === 0) {
            html += '<div class="p-3 text-center text-gray-500">该目录暂无文件</div>';
            fileList.innerHTML = html;
            return;
        }
        // 渲染文件/目录
        res.data.forEach(file => {
            // 目录/文件图标区分
            const icon = file.is_dir 
                ? '<svg class="w-5 h-5 mr-2 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path></svg>'
                : '<svg class="w-5 h-5 mr-2 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path></svg>';
            // 文件大小（目录显示-，文件显示KB）
            const size = file.is_dir ? '-' : `${file.size.toFixed(2)} KB`;
            // 操作按钮（目录=打开，文件=下载）
            const operate = file.is_dir 
                ? `<span class="text-blue-600 mr-3 cursor-pointer" onclick="loadFileList('${file.path}')">打开</span>`
                : `<a href="/api/file/download?path=${file.path}" class="text-blue-600 mr-3" target="_blank" download>下载</a>`;
            // 拼接单条文件/目录HTML
            html += `
                <div class="file-item flex items-center justify-between p-2 hover:bg-gray-50 rounded-lg transition-colors">
                    <div class="flex items-center overflow-hidden">
                        ${icon}
                        <span class="truncate max-w-[200px] sm:max-w-[400px]">${file.name}</span>
                    </div>
                    <div class="flex items-center text-sm text-gray-500 gap-3">
                        <span>${size}</span>
                        <span>${file.mtime}</span>
                        ${operate}
                        <span class="file-delete cursor-pointer text-red-600" data-path="${file.path}">删除</span>
                    </div>
                </div>
            `;
        });
        // 插入到页面
        fileList.innerHTML = html;
        // 重新绑定文件删除事件（动态渲染后）
        document.querySelectorAll('.file-delete').forEach(btn => {
            btn.addEventListener('click', function() {
                const path = this.getAttribute('data-path');
                if (!path) return;
                if (!confirm('⚠️ 确定要删除吗？\n删除后无法恢复！')) return;
                ajax('/api/file/delete', 'POST', {path: path}, function(res) {
                    showMsg(res.msg, res.code !== 0);
                    if (res.code === 0) {
                        loadFileList(document.getElementById('current-path').getAttribute('data-path'));
                    }
                });
            });
        });
    });
}