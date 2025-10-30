#!/usr/bin/env bash
# Kaelion Voice Studio — Instalador automático Nginx + HTTPS + PM2
# Uso:
#   sudo bash kaelion_setup.sh -d TU_DOMINIO -e TU_EMAIL -f /ruta/a/frontend -b /ruta/a/backend
# Ejemplo:
#   sudo bash kaelion_setup.sh -d kaelion.tu-dominio.com -e admin@tu-dominio.com -f /home/ubuntu/kaelion_voice/frontend -b /home/ubuntu/kaelion_voice/backend
set -euo pipefail

# --- Parseo de flags ---
DOMAIN=""
EMAIL=""
FRONTEND_SRC=""
BACKEND_DIR=""
WWW_DIR="/var/www/kaelion_voice/frontend"
NGINX_SITE="/etc/nginx/sites-available/kaelion.conf"
CORS_ORIGIN=""

while getopts ":d:e:f:b:" opt; do
  case $opt in
    d) DOMAIN="$OPTARG" ;;
    e) EMAIL="$OPTARG" ;;
    f) FRONTEND_SRC="$OPTARG" ;;
    b) BACKEND_DIR="$OPTARG" ;;
    \?) echo "Opción inválida -$OPTARG" >&2; exit 1 ;;
    :) echo "La opción -$OPTARG requiere un valor" >&2; exit 1 ;;
  esac
done

if [[ -z "$DOMAIN" || -z "$EMAIL" || -z "$FRONTEND_SRC" || -z "$BACKEND_DIR" ]]; then
  echo "Uso: sudo bash $0 -d DOMINIO -e EMAIL -f /ruta/frontend -b /ruta/backend"
  exit 1
fi

CORS_ORIGIN="https://${DOMAIN}"

echo "==> Dominio: ${DOMAIN}"
echo "==> Email   : ${EMAIL}"
echo "==> Frontend: ${FRONTEND_SRC}  ->  ${WWW_DIR}"
echo "==> Backend : ${BACKEND_DIR}"
sleep 1

# --- 1) Paquetes base ---
echo "==> Instalando Nginx, Certbot, Node (si falta)"
apt-get update -y
apt-get install -y nginx certbot python3-certbot-nginx curl

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt-get install -y nodejs
fi

# --- 2) Directorios y permisos del frontend ---
echo "==> Preparando /var/www/kaelion_voice/frontend"
mkdir -p "${WWW_DIR}"
rsync -ah --delete "${FRONTEND_SRC}/" "${WWW_DIR}/"
chown -R www-data:www-data /var/www/kaelion_voice
chmod -R 755 /var/www/kaelion_voice

# --- 3) Nginx site ---
echo "==> Escribiendo configuración Nginx"
cat > "${NGINX_SITE}" <<NGINX
# kaelion.conf — generado por instalador
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN};

    location /.well-known/acme-challenge/ {
        root ${WWW_DIR};
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN} www.${DOMAIN};

    root ${WWW_DIR};
    index index.html;

    ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "microphone=(), camera=()" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;
    client_max_body_size 50m;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8787/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
        send_timeout 300s;
    }
}
NGINX

ln -sf "${NGINX_SITE}" /etc/nginx/sites-enabled/kaelion.conf
nginx -t
systemctl reload nginx

# --- 4) HTTPS con Let's Encrypt ---
echo "==> Generando certificados para ${DOMAIN}"
certbot --nginx --non-interactive --agree-tos -m "${EMAIL}" -d "${DOMAIN}" -d "www.${DOMAIN}" || true
systemctl reload nginx || true

# --- 5) Backend: .env y dependencias ---
echo "==> Configurando backend"
if [[ ! -f "${BACKEND_DIR}/package.json" ]]; then
  echo "ERROR: No encuentro package.json en ${BACKEND_DIR}"; exit 1
fi

if [[ -f "${BACKEND_DIR}/.env" ]]; then
  sed -i "s|^CORS_ORIGIN=.*|CORS_ORIGIN=${CORS_ORIGIN}|g" "${BACKEND_DIR}/.env" || true
else
  echo "PORT=8787" > "${BACKEND_DIR}/.env"
  echo "CORS_ORIGIN=${CORS_ORIGIN}" >> "${BACKEND_DIR}/.env"
fi

pushd "${BACKEND_DIR}" >/dev/null
npm install
if ! command -v pm2 >/dev/null 2>&1; then
  npm i -g pm2
fi
pm2 start server.js --name kaelion || pm2 restart kaelion
pm2 save
pm2 startup -u $(logname) --hp /home/$(logname) || true
popd >/dev/null

echo "==> Listo. Verifica:"
echo "   Frontend: https://${DOMAIN}"
echo "   API     : https://${DOMAIN}/api/"
echo "   PM2     : pm2 status"
