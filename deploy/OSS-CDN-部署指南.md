# 阿里云 OSS + CDN 部署指南（科瑞斯官网）

> 适用对象：`index.html` + `assets/` 的纯静态站点（本项目）
> 目标架构：**用户 → CDN 边缘节点（缓存）→ 回源 OSS Bucket（源站）**
> 预期成本：OSS 存储约 0.12 元/GB/月 + CDN 流量约 0.24 元/GB（大陆），本项目千次访问/月约 2~3 元，见文末费用估算

---

## 0. 前置条件

| 项目 | 要求 |
|---|---|
| 阿里云账号 | 已实名认证 |
| 域名 | **必须已 ICP 备案**（Bucket 在中国内地时，绑定自定义域名强制要求备案；未备案域名无法通过 CDN 对外加速） |
| 域名解析权 | 可在 DNS 服务商（阿里云云解析/其他）添加记录 |
| 本地文件 | `index.html` + `assets/`（本目录已就绪） |

**备案**：阿里云 ICP 备案（beian.aliyun.com），个人/企业均可，一般 1~2 周；备案期间可用服务器 IP 或内网预览，公网正式上线需等备案通过。

---

## 1. 创建 OSS Bucket

1. 登录 [OSS 控制台](https://oss.console.aliyun.com/) → 左侧「Bucket 列表」→「创建 Bucket」
2. 关键参数：

| 参数 | 建议值 |
|---|---|
| Bucket 名称 | `kerrus-site`（全局唯一，自定义） |
| 地域 | 华东1（杭州）或离你客户最近的地域 |
| 读写权限 | **公共读**（`public-read`）—— 否则浏览器无法直接加载 |
| 版本控制 | 关闭（静态站无需） |
| 服务端加密 | 默认关闭即可 |

## 2. 上传网站文件

### 方式 A：控制台手动（一次性）
Bucket 内「文件管理」→ 上传 `index.html`，再上传 `assets/` 文件夹。

### 方式 B：ossutil 命令行（推荐，可重复发布）
安装 ossutil（[下载地址](https://help.aliyun.com/zh/oss/ossutil)，macOS 用 `brew install aliyun-cli` 或下载二进制），执行一次配置：

```bash
ossutil config
# 依次填写：Endpoint（如 oss-cn-hangzhou.aliyuncs.com）、AccessKey ID/Secret（RAM 子账号）、Language
```

一键上传：

```bash
ossutil sync index.html oss://kerrus-site/index.html -u
ossutil sync assets/ oss://kerrus-site/assets/ -u
```

## 3. 开启静态网站托管

Bucket →「Bucket 配置」→「静态页面」→ 开启：

- 默认首页：`index.html`
- 默认 404 页面：留空或传一个 `404.html`

> ⚠️ **关键限制**：直接用 Bucket 域名（`kerrus-site.oss-cn-hangzhou.aliyuncs.com`）访问 HTML 时，浏览器会**强制下载而不是显示网页**。必须绑定自定义域名（第 4 步）才能在线预览；且 **2025-03-20 起 OSS 中国内地新用户用默认 endpoint 访问数据接口会被拒绝**，正式对外必须走自定义域名/CDN。

## 4. 绑定自定义域名（OSS）

Bucket →「Bucket 配置」→「域名管理」→「绑定域名」：

1. 输入加速域名，如 `www.kerrus.com`（建议用子域名，如 `www` 或 `oss`）
2. 按提示添加 **CNAME 验证记录**（或 TXT）验证域名所有权
3. 绑定成功后，此域名即可直接访问 OSS（先不经 CDN 也可以预览）

## 5. 接入 CDN 加速（正式对外推荐）

1. 开通 [CDN](https://cdn.console.aliyun.com/)（按量付费，开通免费）
2. 「域名管理」→「添加域名」：

| 参数 | 值 |
|---|---|
| 加速域名 | `www.kerrus.com`（与第 4 步一致） |
| 加速区域 | 仅中国大陆 / 全球 |
| 业务类型 | **图片小文件**（静态网站场景） |
| 源站类型 | **OSS 域名** → 选择 Bucket `kerrus-site` |
| 回源 HOST | 使用默认（Bucket 域名）即可 |

3. 添加后 CDN 会给出 **CNAME 地址**（形如 `www.kerrus.com.w.cdngslb.com`），到 DNS 服务商把 `www.kerrus.com` 的 CNAME 指向它（原来指向 OSS 的 CNAME 需改/删除）
4. 等待 CNAME 生效（`nslookup www.kerrus.com` 应返回 CDN 域名）

## 6. 配置 HTTPS 证书

CDN「域名管理」→ 目标域名 →「HTTPS 配置」：

1. 「免费证书」：如已有阿里云免费 DV 证书可直接关联；没有则在 [数字证书管理服务](https://cas.console.aliyun.com/) 申请免费证书（约 5 分钟签发，有效期 3 个月，需续期）
2. 开启「HTTPS 安全加速」
3. 建议同时开启「HTTP/2」与「强制 HTTPS 跳转」（301）

## 7. 缓存配置（重要：HTML 不能长缓存）

CDN「缓存配置」→「缓存过期时间」→ 添加规则：

| 类型 | 规则 | 说明 |
|---|---|---|
| 文件后缀名 | `html` | 过期时间 **0 秒**（或 no-cache），保证改版即时生效 |
| 文件后缀名 | `js;css;png;jpg;jpeg;svg;ico;woff2` | 30 天（静态资源带版本号或刷新即可更新） |
| 目录 | `/assets/` | 30 天 |

> 修改网站后：重新执行上传命令，再到 CDN 控制台「刷新预热」→「URL 刷新」输入 `https://www.kerrus.com/index.html` 刷新缓存。

## 8. 可选加固

- **防盗链**：OSS「权限管理」→「防盗链」→ 设置 Referer 白名单（仅允许你的域名），避免图片被站外盗用
- **费用告警**：阿里云「费用中心」→ 预算管理，设置月预算与告警阈值
- **CDN 增值**：可开启 Brotli 压缩、图片缩放（不影响本 HTML 站）

---

## 验证清单

- [ ] `nslookup www.kerrus.com` 返回 CDN CNAME
- [ ] 浏览器访问 `https://www.kerrus.com` 正常显示首页（非下载）
- [ ] 图片 `https://www.kerrus.com/assets/semiconductor.png` 可打开
- [ ] `curl -I https://www.kerrus.com/index.html` 返回 `200`，无 `Content-Disposition: attachment`
- [ ] 修改一段文字上传后，刷新 CDN 缓存，页面立即更新

## 费用估算（本项目规模）

| 项 | 单价 | 千次访问/月估算 |
|---|---|---|
| OSS 存储 | ~0.12 元/GB/月 | 站点 < 0.6MB，约 0 元 |
| OSS 请求费 | 约 0.01 元/万次 | 忽略 |
| CDN 流量（大陆） | ~0.24 元/GB | 页面+图片约 1.5MB/次 → 约 0.4 元 |
| CDN 请求数 | 约 0.02 元/万次 | 忽略 |
| **合计** | | **≈ 0.5~2.5 元/月** |

## 常见问题

| 现象 | 原因与处理 |
|---|---|
| 访问返回 403/提示未备案 | 域名未备案或备案未通过，先完成 ICP 备案 |
| HTML 被下载而非显示 | 未绑定自定义域名；Bucket 域名默认强制下载 |
| CNAME 生效慢 | DNS 缓存，等 5~30 分钟，用 `nslookup` 确认 |
| 改版不生效 | 未刷新 CDN 缓存，到「刷新预热」刷新 index.html |
| 图片 403 | 防盗链白名单未包含你的域名，或 CDN 回源鉴权未配置 |

> 本文档基于阿里云官方文档（2026-09 检索）：静态网站托管、通过自定义域名访问 OSS、CDN 加速 OSS、ossutil sync 命令。
