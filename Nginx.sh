# Установка Nginx 
sudo curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null && \
sudo gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg && \
sudo echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian bullseye nginx" | sudo tee /etc/apt/sources.list.d/nginx.list && \
sudo echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx && \
sudo apt update && \
sudo wget http://ftp.ru.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.1n-0+deb11u3_amd64.deb && \
sudo dpkg -i libssl1.1_1.1.1n-0+deb11u3_amd64.deb && \
sudo rm libssl1.1_1.1.1n-0+deb11u3_amd64.deb && \
sudo apt install -y nginx && \
mkdir -m 777 -p /etc/nginx/sites-available /etc/nginx/sites-enabled /var/www/iotserv.ru
sudo sed -i 32i\ 'include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf && \
sudo nginx -t && \
sudo service nginx reload && \
sudo systemctl restart nginx



########## Создание сайта Nginx c доменным именем your-domain.com
sudo mkdir -m 777 -p /var/www/your-domain.com
sudo cat > /etc/nginx/sites-available/your-domain.com <<EOF
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
	listen 443 ssl;
	server_name www.your-domain.com;
	root /var/www/your-domain.com;

	ssl_certificate /etc/nginx/sites-available/cert.crt;
	ssl_certificate_key /etc/nginx/sites-available/key.pem;

	index index.html;

	location / {
		try_files $uri $uri/ /index.html;
	}
}
EOF



########## Скопировать файлы сайта в директорию   /var/www/your-domain.com



########## Настройка https переадресаций на доменное имя + прокси на https с tls сертификатом
sudo cat > /etc/nginx/sites-available/proxy <<EOF
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
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
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
	proxy_set_header Connection "upgrade";
   	proxy_set_header Upgrade $http_upgrade;
	proxy_set_header Host $host;
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
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
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
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
  }
}
EOF



sudo ln -s /etc/nginx/sites-available/your-domain.com /etc/nginx/sites-enabled/ && \
sudo ln -s /etc/nginx/sites-available/proxy /etc/nginx/sites-enabled/proxy
sudo nginx -t && \
sudo service nginx reload && \
sudo systemctl restart nginx
