#!/bin/bash
set -e
echo "=========================================="
echo "Setting up Nginx for Benchmarking"
echo "=========================================="
echo "[1/4] Installing Nginx and Wrk..."
sudo apt-get update
sudo apt-get install -y nginx wrk
echo "Nginx version: $(nginx -v 2>&1)"
echo "Wrk version: $(wrk --version | grep -o 'wrk [0-9.]*')"
echo ""
echo "[2/4] Generating static test files..."
sudo mkdir -p /var/www/html/static
sudo dd if=/dev/urandom of=/var/www/html/static/1kb.html bs=1K count=1 status=none
sudo dd if=/dev/urandom of=/var/www/html/static/10kb.html bs=1K count=10 status=none
sudo dd if=/dev/urandom of=/var/www/html/static/100kb.html bs=1K count=100 status=none
sudo tee /var/www/html/test.html > /dev/null <<EOF
<!DOCTYPE html>
<html>
<head><title>Performance Test</title></head>
<body>
<h1>Nginx Benchmark Page</h1>
<p>Files available for testing:</p>
<ul>
    <li><a href="/static/1kb.html">1KB File</a></li>
    <li><a href="/static/10kb.html">10KB File</a></li>
    <li><a href="/static/100kb.html">100KB File</a></li>
</ul>
</body>
</html>
EOF
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
echo ""
echo "[3/4] Configuring Nginx..."
sudo tee /etc/nginx/sites-available/benchmark > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    access_log off;
    error_log /var/log/nginx/error.log crit;
    location / {
        root /var/www/html;
        index test.html;
    }
    location /static/ {
        alias /var/www/html/static/;
        expires 1y;
        add_header Cache-Control "public, no-transform";
    }
}
EOF
sudo ln -sf /etc/nginx/sites-available/benchmark /etc/nginx/sites-enabled/
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi
echo ""
echo "[4/4] Verifying and Starting Nginx..."
if sudo nginx -t; then
    echo "Configuration syntax looks good."
    sudo systemctl restart nginx
else
    echo "Error: Nginx configuration failed check."
    exit 1
fi
echo "Testing local access..."
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/static/1kb.html)
if [ "$STATUS_CODE" == "200" ]; then
    echo "✓ Success! Nginx is serving content (HTTP 200)."
    echo "  Try running: curl http://localhost/static/1kb.html"
else
    echo "x Warning: Expected HTTP 200 but got $STATUS_CODE"
fi
echo ""
echo "=========================================="
echo "Nginx Setup Completed!"
echo "=========================================="