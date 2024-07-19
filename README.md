## 项目概述

本项目提供了一个基于 Docker 的 Nginx 配置示例，旨在简化 Nginx 服务器的部署和管理。项目使用 Docker Compose 来编排服务，包括 Nginx 服务器、SSL 证书管理（通过 Certbot）以及实时日志分析（通过 GoAccess）。用户可以通过简单的配置文件快速启动一个具有 HTTPS 支持和实时日志分析功能的 Nginx 服务器。

## 目录结构

```apl
├── docker-compose.yml       # Docker Compose 配置文件
├── env.sample               # 环境变量示例文件
├── nginx
│   ├── conf.d
│   │   └── default.conf     # Nginx 默认服务器配置
│   ├── logs
│   │   ├── access.log       # 访问日志文件
│   │   └── error.log        # 错误日志文件
│   ├── ssl
│   └── www
│       └── index.html       # 网站默认首页
└── nginx.conf               # Nginx 主配置文件
```

## 使用方法

### 1. 环境变量配置

首先，复制 `env.sample` 文件为 `.env` 文件，并根据需要修改环境变量：

```bash
cp env.sample .env
```

编辑 `.env` 文件，设置你的域名和邮箱：

```bash
DOMAIN_NAME=example.com
EMAIL=example@example.com
```

### 2. 创建和配置 Docker Compose 文件

确保 `docker-compose.yml` 文件包含了所有必要的配置和服务定义。以下是示例配置：

```yaml
services:
  nginx:
    image: nginx:latest
    container_name: nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/letsencrypt
      - ./nginx/www:/var/www/html
      - ./nginx/logs:/var/log/nginx
    ports:
      - "80:80"
      - "443:443"
    entrypoint: /bin/sh -c "envsubst '\$DOMAIN_NAME' < /etc/nginx/nginx.conf > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"
    env_file:
      - .env
    depends_on:
      - certbot
      - goaccess

  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - ./nginx/ssl:/etc/letsencrypt
      - ./nginx/www:/var/www/html
    entrypoint: "/bin/sh -c 'if [ ! -f /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem ]; then certbot certonly --standalone --email ${EMAIL} --agree-tos --no-eff-email -d ${DOMAIN_NAME} -d www.${DOMAIN_NAME}; fi; trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"
    env_file:
      - .env

  goaccess:
    image: allinurl/goaccess
    container_name: goaccess
    volumes:
      - ./nginx/logs:/var/log/nginx
      - ./nginx/www:/var/www/html
    ports:
      - "7890:7890"
    command: /usr/bin/goaccess /var/log/nginx/access.log --log-format=COMBINED --real-time-html -o /var/www/html/report.html
```

### 3. 配置 Nginx

确保 `nginx.conf` 和 `default.conf` 文件正确配置了 Nginx。

#### `nginx.conf`

```shell
# nginx.conf

user  nginx;
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    # Log configuration
    access_log  /var/log/nginx/access.log;
    error_log   /var/log/nginx/error.log;

    include /etc/nginx/conf.d/*.conf;
}
```

#### `default.conf`

```bash
# default.conf

server {
    listen 80;
    server_name ${DOMAIN_NAME} www.${DOMAIN_NAME};

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        root /var/www/html;
        index index.html;
    }
}

server {
    listen 443 ssl;
    server_name ${DOMAIN_NAME} www.${DOMAIN_NAME};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem;

    location / {
        root /var/www/html;
        index index.html;
    }
}
```

### 4. 启动服务

使用以下命令启动 Docker Compose 服务：

```bash
docker-compose up -d
```

### 5. 验证和访问

1. **访问默认页面**： 访问 `http://example.com` 或 `http://www.example.com`，确保默认的 `index.html` 页面显示正确。

2. **检查 SSL 证书**： 访问 `https://example.com` 或 `https://www.example.com`，确保 SSL 证书正确配置。

3. **查看 GoAccess 报告**：
访问 `https://example.com/goaccess/` 查看实时日志报告。此路径通过 Nginx 转发到 GoAccess 服务，显示正确的报告。

4. **查看日志**： 使用以下命令查看 Nginx 和 Certbot 容器的日志：

   ```bash
   docker logs nginx
   docker logs certbot
   ```

### 许可证

本项目是开源的，采用 MIT 许可证。