# KERRUS 官网 · 云服务器部署说明

站点为**纯静态单文件**（`index.html`，无后端、无数据库、无构建步骤），任意 Web 服务器（Nginx / Apache / Caddy）或对象存储托管均可。以下以最常见的 **Linux 云服务器 + Nginx** 为例。

## 一、文件清单

```
WebSite/
├── index.html                # 网站本体（双击即可浏览）
├── assets/
│   └── semiconductor.png     # 半导体设备案例配图（与 index.html 一起部署）
└── deploy/
    ├── server-init.sh        # 服务器一次性初始化（装 Nginx、建目录、写配置）
    ├── deploy.sh             # 本地一键发布（rsync 同步 + 平滑重载）
    ├── nginx-kerrus.conf     # Nginx 配置完整版（含注释/HTTPS 指引）
    ├── OSS-CDN-部署指南.md   # 阿里云 OSS+CDN 部署手册
    └── README-部署说明.md    # 本文档
```

## 二、最快路径（约 5 分钟）

### 方式 A：一键脚本（推荐）

1. 本地把整个目录上传到服务器（或用 scp）：
   ```bash
   scp -r WebSite root@<服务器IP>:/root/
   ```
2. 登录服务器执行初始化：
   ```bash
   ssh root@<服务器IP>
   cd /root/WebSite
   bash deploy/server-init.sh
   cp -r index.html assets /var/www/kerrus/
   ```
3. 浏览器访问 `http://<服务器IP>/` 即可看到网站。

### 方式 B：手动部署

```bash
sudo apt update && sudo apt install -y nginx
sudo mkdir -p /var/www/kerrus
sudo cp -r index.html assets /var/www/kerrus/
sudo cp deploy/nginx-kerrus.conf /etc/nginx/conf.d/kerrus.conf
sudo rm -f /etc/nginx/sites-enabled/default   # Ubuntu 默认站点占用 80 时
sudo nginx -t && sudo systemctl reload nginx
```

### 方式 C：后续每次更新网站

在你本地电脑修改 `index.html` 后：
1. 编辑 `deploy/deploy.sh`，把 `SERVER="root@你的服务器IP"` 改成实际登录地址；
2. 执行 `bash deploy/deploy.sh`，自动完成同步与重载，不断线。

## 三、云厂商控制台必做

| 项目 | 设置 |
|---|---|
| 安全组 / 防火墙入站规则 | 放行 **TCP 80**（HTTP）；要上 HTTPS 再放行 **TCP 443** |
| 系统防火墙（ufw/firewalld） | 同步放行 80/443（server-init.sh 对 ufw 已自动处理） |
| 域名解析 | 在 DNS 控制台添加 A 记录指向服务器公网 IP |
| ICP 备案 | **中国大陆地域服务器绑定域名必须完成 ICP 备案**，否则 80/443 会被拦截；仅用 IP 访问无需备案 |
| HTTPS 证书 | 域名生效后执行 `sudo certbot --nginx -d 你的域名`，自动申请并配置跳转 |

## 四、CentOS / openEuler / 麒麟差异

```bash
sudo dnf install -y nginx
sudo mkdir -p /var/www/kerrus && sudo cp -r index.html assets /var/www/kerrus/
sudo cp deploy/nginx-kerrus.conf /etc/nginx/conf.d/kerrus.conf   # 把 server_name 第一行末尾的 _ 保留即可
sudo nginx -t && sudo systemctl enable --now nginx && sudo systemctl reload nginx
sudo firewall-cmd --permanent --add-service=http --add-service=https
sudo firewall-cmd --reload
```

## 五、其他托管方式（无需服务器）

- **对象存储静态网站**：阿里云 OSS / 腾讯云 COS 开启「静态网站托管」，上传 `index.html` + `assets/` 即可，再用 CDN 加速（详见 `OSS-CDN-部署指南.md`）。
- **Nginx Docker 一行起**：
  ```bash
  docker run -d --name kerrus -p 80:80 \
    -v $(pwd)/index.html:/usr/share/nginx/html/index.html:ro \
    -v $(pwd)/assets:/usr/share/nginx/html/assets:ro nginx:stable-alpine
  ```

## 六、联系方式与上线前补充

- 页面联系方式已更新为：商务邮箱 `jasonshen@kerrus.com`、联系电话 `15601655630`；
- 地址目前为「江苏省南京市江北新区」，如有详细门牌可一并补全。
