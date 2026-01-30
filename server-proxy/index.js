const express = require('express');
const fetch = require('node-fetch');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;
const QDRANT_URL = process.env.QDRANT_URL; // e.g. https://<cluster>.gcp.cloud.qdrant.io
const QDRANT_API_KEY = process.env.QDRANT_API_KEY;

if (!QDRANT_URL || !QDRANT_API_KEY) {
  console.error('Please set QDRANT_URL and QDRANT_API_KEY environment variables.');
  process.exit(1);
}

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Proxy all requests under /qdrant/* to the Qdrant Cloud cluster, injecting the api-key header
app.all('/qdrant/*', async (req, res) => {
  try {
    const targetPath = req.originalUrl.replace(/^\/qdrant/, '');
    const targetUrl = `${QDRANT_URL}${targetPath}`;

    const headers = {
      'api-key': QDRANT_API_KEY,
    };

    // Preserve content-type if present
    if (req.get('Content-Type')) {
      headers['Content-Type'] = req.get('Content-Type');
    }

    const fetchOptions = {
      method: req.method,
      headers,
    };

    if (!['GET', 'HEAD'].includes(req.method)) {
      fetchOptions.body = JSON.stringify(req.body);
    }

    const proxied = await fetch(targetUrl, fetchOptions);
    const text = await proxied.text();
    res.status(proxied.status);
    // Try to forward content-type
    const contentType = proxied.headers.get('content-type');
    if (contentType) res.set('Content-Type', contentType);
    res.send(text);
  } catch (err) {
    console.error('Proxy error', err);
    res.status(500).json({ error: 'Proxy error', details: String(err) });
  }
});

// (Appwrite proxy removed — this proxy only forwards /qdrant/* to Qdrant)

app.listen(PORT, () => console.log(`Proxy listening on port ${PORT}`));
