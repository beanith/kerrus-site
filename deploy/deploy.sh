#!/usr/bin/env bash
# ============================================================
# KERRUS 静态站点 —— 本地一键发布脚本（在你的电脑上运行）
# 作用：把 index.html + assets/ 同步到云服务器并平滑重载 nginx
#
# 首次使用：
#   1) chmod +x deploy/deploy.sh
#   2) 修改下面的 SERVER 为你的服务器，例如 root@123.45.67.89
#   3) 确保本机可 ssh 登录该服务器（建议配置密钥登录）
#   4) 服务器已先执行过 server-init.sh
#
# 之后每次更新网站，只需：./deploy/deploy.sh
# ============================================================
set -euo pipefail

SERVER="root@你的服务器IP"          # ←← 修改这里
REMOTE_DIR="/var/www/kerrus"
LOCAL_FILE="index.html"
LOCAL_ASSETS="assets"

cd "$(dirname "$0")/.."

echo "==> [1/4] 语法自检：文件存在性"
[ -f "${LOCAL_FILE}" ] || { echo "未找到 ${LOCAL_FILE}"; exit 1; }
[ -d "${LOCAL_ASSETS}" ] || { echo "未找到 ${LOCAL_ASSETS}/ 目录"; exit 1; }

echo "==> [2/4] 同步文件到 ${SERVER}:${REMOTE_DIR}"
ssh "${SERVER}" "mkdir -p ${REMOTE_DIR}/assets"
rsync -avz --chown=www-data:www-data "${LOCAL_FILE}" "${SERVER}:${REMOTE_DIR}/index.html"
rsync -avz --chown=www-data:www-data "${LOCAL_ASSETS}/" "${SERVER}:${REMOTE_DIR}/assets/"

echo "==> [3/4] 校验并重载 nginx"
ssh "${SERVER}" "nginx -t && systemctl reload nginx"

echo ""
echo "==> [4/4] 发布完成：http://${SERVER#*@}/"
