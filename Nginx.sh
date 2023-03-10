# Установка Nginx 
apt update  && \
apt install -y wget curl gpg && \
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null && \
gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian bullseye nginx" | tee /etc/apt/sources.list.d/nginx.list && \
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx && \
wget http://ftp.ru.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.1n-0+deb11u3_amd64.deb && \
dpkg -i libssl1.1_1.1.1n-0+deb11u3_amd64.deb && \
rm libssl1.1_1.1.1n-0+deb11u3_amd64.deb && \
apt update && \
apt install -y nginx && \
sed -i 32i\ 'include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf && \
systemctl restart nginx



########## Создание сайта Nginx c доменным именем your-domain.com
sudo mkdir -m 777 -p /var/www/your-domain.com
nano /etc/nginx/sites-available/your-domain.com
server {
	listen 80;
	server_name your-domain.com;
	return 301 https://www.your-domain.com$request_uri;
}

server {
	listen 80;
	server_name www.your-domain.com;
	root /var/www/your-domain.com;

	index index.html;

	location / {
		try_files $uri $uri/ /index.html;
	}
}

server {
	listen 443 ssl http2;
	server_name www.your-domain.com;
	root /var/www/your-domain.com;

	ssl_certificate /etc/nginx/sites-available/cert.crt;
	ssl_certificate_key /etc/nginx/sites-available/key.pem;

	index index.html;

	location / {
		try_files $uri $uri/ /index.html;
	}
}



########## Скопировать файлы сайта в директорию   /var/www/your-domain.com



########## Настройка https переадресаций на доменное имя + прокси на https с tls сертификатом
nano /etc/nginx/sites-available/proxy

# Grafana primary listener and redirect
server {
  listen 80;
  server_name grafana.your-domain.com;
  return 301 https://$host$request_uri;
}

# Grafana ssl config
server {
  listen 443 ssl http2;
  server_name grafana.your-domain.com;
  
  ssl_certificate /etc/nginx/sites-available/cert.crt;
  ssl_certificate_key /etc/nginx/sites-available/key.pem;

  location / {
  proxy_pass http://127.0.0.1:3000;
  proxy_set_header Host $host;
  proxy_set_header Connection "upgrade";
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  add_header X-Http-Version $server_protocol;
  }
}


####################################################################


# Influxdb primary listener and redirect
server {
  listen 80;
  server_name influxdb.your-domain.com;
  return 301 https://$host$request_uri;
}

# Influxdb ssl config
server {
  listen 443 ssl http2;
  server_name influxdb.your-domain.com;

  ssl_certificate /etc/nginx/sites-available/cert.crt;
  ssl_certificate_key /etc/nginx/sites-available/key.pem;

  location / {
  proxy_pass http://127.0.0.1:8086;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  add_header X-Http-Version $server_protocol;
  }
}


####################################################################


# Nodered primary listener and redirect
server {
  listen 80;
  server_name nodered.your-domain.com;
  return 301 https://$host$request_uri;
}

# Nodered ssl config
server {
  listen 443 ssl http2;
  server_name nodered.your-domain.com;

  ssl_certificate /etc/nginx/sites-available/cert.crt;
  ssl_certificate_key /etc/nginx/sites-available/key.pem;
  
  location / {
  proxy_pass http://127.0.0.1:1880;
  proxy_set_header Host $host;
  proxy_set_header Connection "upgrade";
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  add_header X-Http-Version $server_protocol;
  }
}


####################################################################


# Chirpstack primary listener and redirect
server {
  listen 80;
  server_name chirpstack.your-domain.com;
  return 301 https://$host$request_uri;
}

# Chirpstack ssl config
server {
  listen 443 ssl http2;
  server_name chirpstack.your-domain.com;

  ssl_certificate /etc/nginx/sites-available/cert.crt;
  ssl_certificate_key /etc/nginx/sites-available/key.pem;
  
  location / {
  proxy_pass http://127.0.0.1:8080;
  proxy_set_header Host $host;
  proxy_set_header Connection "upgrade";
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  add_header X-Http-Version $server_protocol;
  }
}


####################################################################


# Chirpstack-api primary listener and redirect
server {
  listen 80;
  server_name chirpstack-api.your-domain.com;
  return 301 https://$host$request_uri;
}

# Chirpstack-api ssl config
server {
  listen 443 ssl http2;
  server_name chirpstack-api.your-domain.com;

  ssl_certificate /etc/nginx/sites-available/cert.crt;
  ssl_certificate_key /etc/nginx/sites-available/key.pem;
  
  location / {
  proxy_pass http://127.0.0.1:8090;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  add_header X-Http-Version $server_protocol;
  }
}


#Правки в основнмо конфиг файле nginx, итоговый должен быть таким:
nano /etc/nginx/nginx.conf

user  nginx;
worker_processes  auto;
worker_cpu_affinity auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
    use epoll;
    multi_accept on;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
   
    server_tokens off;
    sendfile        on;
    
    keepalive_timeout  65;
    
    tcp_nopush on;
    tcp_nodelay on;
    
    gzip on;
    gzip_buffers 64 8k;
    gzip_comp_level 5;
    gzip_min_length 512;
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript;
    gzip_proxied any;

    fastcgi_buffer_size 128k;
    fastcgi_buffers 4 256k;
    fastcgi_busy_buffers_size 256k;
    fastcgi_read_timeout 120s;
    
    map $scheme $fastcgi_https {
      default off;
      https on;
    }
    
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}


sudo ln -s /etc/nginx/sites-available/your-domain.com /etc/nginx/sites-enabled/ && \
sudo ln -s /etc/nginx/sites-available/proxy /etc/nginx/sites-enabled/proxy
sudo nginx -t && \
sudo service nginx reload && \
sudo systemctl restart nginx
