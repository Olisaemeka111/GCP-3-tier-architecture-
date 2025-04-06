#!/bin/bash
apt-get update
apt-get install -y nginx
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Frontend Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            text-align: center;
        }
        h1 {
            color: #333;
        }
    </style>
</head>
<body>
    <h1>Frontend Server</h1>
    <p>Welcome to the Three-Tier Application</p>
</body>
</html>
EOF
systemctl enable nginx
systemctl start nginx
