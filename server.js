const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    // Guarda con marca de tiempo para evitar colisiones
    const safeName = file.originalname.replace(/\s+/g, '_');
    cb(null, `${Date.now()}-${safeName}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 200 * 1024 * 1024 } // límite 200 MB (ajusta según necesites)
});

const app = express();

// CORS simple — en producción cambia '*' por tu dominio
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

app.post('/api/voices', upload.single('voiceFile'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded (field name must be "voiceFile")' });

  const { name, email, consent } = req.body;
  console.log('Received upload:', {
    originalname: req.file.originalname,
    storedName: req.file.filename,
    size: req.file.size,
    name, email, consent
  });

  // Aquí puedes agregar procesamiento adicional (p. ej. enviar a un pipeline de ML)
  return res.json({
    ok: true,
    message: 'File received',
    file: `/uploads/${req.file.filename}`,
    meta: { name, email, consent }
  });
});

// Servir carpeta uploads de prueba (opcional)
app.use('/uploads', express.static(uploadDir));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API server listening on http://localhost:${PORT}`));