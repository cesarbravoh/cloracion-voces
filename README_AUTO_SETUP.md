# Kaelion Voice Studio — Instalador automático
Este script configura:
- Nginx + HTTPS (Let’s Encrypt)
- Copia tu frontend a /var/www/kaelion_voice/frontend
- Crea el sitio Nginx con proxy a /api -> localhost:8787
- Ajusta CORS_ORIGIN en el backend y lanza PM2

## Uso
```bash
sudo bash kaelion_setup.sh -d TU_DOMINIO -e TU_EMAIL -f /ruta/a/frontend -b /ruta/a/backend
```

### Ejemplo
```bash
sudo bash kaelion_setup.sh   -d kaelion.tu-dominio.com   -e admin@tu-dominio.com   -f /home/ubuntu/kaelion_voice/frontend   -b /home/ubuntu/kaelion_voice/backend
```

Al terminar:
- Frontend: https://TU_DOMINIO
- API: https://TU_DOMINIO/api/
- Revisa logs: `pm2 logs kaelion --lines 100`
