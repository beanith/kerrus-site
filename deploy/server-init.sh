#!/usr/bin/env bash
# ============================================================
# KERRUS 静态站点 —— 云服务器一次性初始化脚本（在服务器上以 root 运行）
# 适用：Ubuntu 20.04/22.04/24.04、Debian 11/12（CentOS 见 README 说明）
# 用法：
#   sudo bash server-init.sh
# ============================================================
set -euo pipefail

SITE_DIR=/var/www/kerrus
NGINX_CONF=/etc/nginx/conf.d/kerrus.conf

echo "==> [1/4] 安装 nginx"
if ! command -v nginx >/dev/null 2>&1; then
  apt-get update
  apt-get install -y nginx
else
  echo "    nginx 已存在，跳过"
fi

echo "==> [2/4] 创建站点目录 ${SITE_DIR}"
mkdir -p "${SITE_DIR}"
chown -R www-data:www-data "${SITE_DIR}"

echo "==> [3/4] 写入站点配置"
cat > "${NGINX_CONF}" <<'EOF'
server {
    listen       80;
    listen       [::]:80;
    server_name  _;
    root         /var/www/kerrus;
    index        index.html;

    gzip              on;
    gzip_vary         on;
    gzip_comp_level   6;
    gzip_min_length   1024;
    gzip_types        text/plain text/css text/xml application/javascript
                      application/json image/svg+xml;

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options        "SAMEORIGIN" always;

    location = /index.html { add_header Cache-Control "no-cache, must-revalidate"; }
    location ~* \.(?:css|js|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        expires 30d; add_header Cache-Control "public"; access_log off;
    }
    location / { try_files $uri $uri/ /index.html; }
    location ~ /\.(?!well-known) { deny all; }
}
EOF

# Ubuntu 默认站点可能占用 80，移除软链（不删源文件）
[ -f /etc/nginx/sites-enabled/default ] && rm -f /etc/nginx/sites-enabled/default || true

echo "==> [4/4] 校验配置并重载"
nginx -t
systemctl enable --now nginx
systemctl reload nginx

# UFW 防火墙（如启用）
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp  || true
  ufw allow 443/tcp || true
fi

echo ""
echo "============================================================"
echo " 初始化完成。请把 index.html 与 assets/ 上传到 ${SITE_DIR}/ 后访问："
echo "   http://<服务器公网IP>/"
echo " 云厂商安全组记得放行 80（HTTP）/ 443（HTTPS）入站规则"
echo "============================================================"
