# 🌌 Kaelion Voice Studio — Ethical AI Voice Cloning System

## 🧭 Overview
**Kaelion Voice Studio** is a complete environment to create, manage, and host an ethical AI voice cloning system, developed by **Cebrameta Arte Digital**.  
It includes a frontend, backend, automated setup scripts, and server configurations (Nginx + HTTPS + PM2).

The system ensures security, transparency, and total control over digital voices, following ethical standards of consent and privacy.

---

## 🧩 Main Components
```
kaelion_voice_form_mvp/
├── frontend/
│   └── index.html              ← Landing page + voice upload & consent form
├── backend/
│   ├── server.js               ← Node.js/Express server
│   ├── package.json
│   ├── .env.example
│   ├── uploads/                ← Voice files
│   └── data/                   ← JSON consent records
└── README.md
```

---

## ⚙️ Manual Installation

### Requirements
- Ubuntu / Debian / Linux VPS  
- Node.js 18+  
- Nginx + Certbot (for HTTPS)  
- PM2 (for backend process management)

### Backend Setup
```bash
cd backend
cp .env.example .env
npm install
npm start   # or pm2 start server.js --name kaelion
```

### Frontend Setup
Upload `/frontend` to `/var/www/kaelion_voice/frontend`.

`.env` example:
```
PORT=8787
CORS_ORIGIN=https://your-domain.com
```

---

## 🌐 Nginx Server Configuration

### Recommended Paths
- Frontend → `/var/www/kaelion_voice/frontend`
- Backend → `localhost:8787`

### Nginx Config File
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    root /var/www/kaelion_voice/frontend;
    index index.html;

    ssl_certificate     /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location /api/ {
        proxy_pass http://127.0.0.1:8787/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

Enable & test:
```bash
sudo ln -s /etc/nginx/sites-available/kaelion.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

HTTPS:
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

---

## 🤖 Automated Setup

### Quick Command
```bash
sudo bash kaelion_setup.sh -d YOUR_DOMAIN -e YOUR_EMAIL -f /path/to/frontend -b /path/to/backend
```

Example:
```bash
sudo bash kaelion_setup.sh   -d voice.kaelion.com   -e admin@kaelion.com   -f /home/ubuntu/kaelion_voice/frontend   -b /home/ubuntu/kaelion_voice/backend
```

✅ Automatically:
- Installs Nginx + Certbot + Node.js  
- Copies frontend to `/var/www/kaelion_voice/frontend`  
- Configures SSL + proxy `/api`  
- Generates `.env`  
- Runs backend with PM2  

---

### Interactive Setup
```bash
sudo bash kaelion_setup_interactive.sh
```
Prompts for:
- Domain name  
- Email for Certbot  
- Frontend and backend paths  

---

## 🔒 Security & Ethics
- Only clone your own voice or voices with **explicit consent**.  
- Each record includes a SHA-256 hash, IP, timestamp, and digital signature.  
- Audio is encrypted and removable on demand.  
- All generated audio contains an **AI watermark**.

---

## 💡 API Endpoints
| Method | Route | Description |
|--------|------|-------------|
| `POST` | `/api/voices` | Upload voice & create record |
| `GET` | `/api/consents/:hash` | Retrieve consent record |
| `DELETE` | `/api/models/:id` | Delete model (Right to Erasure) |

---

## 🧠 Local Testing
```bash
npm install -g live-server
live-server frontend/
# In another terminal:
cd backend && npm start
```
Then open:
```
http://localhost:5500
```

---

## 💬 Cosmic Credits
**Author:** César Augusto Bravo Hernández (Kaelion Vor-El)  
**Development & Design:** Cebrameta Arte Digital  
**Location:** Valle de Santiago, Guanajuato, México  
**Email:** cebrameta@gmail.com  
**Website:** [https://cebremeta.com](https://cebremeta.com)

---

✨ *Crafted with cosmic love by Cebrameta 💚 — Empowering your voice in the digital universe.* ✨
