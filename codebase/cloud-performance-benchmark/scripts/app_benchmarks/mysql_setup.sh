#!/bin/bash
set -e
echo "=========================================="
echo "Installing MySQL and Sysbench"
echo "=========================================="
sudo apt-get update
echo "Installing MySQL Server..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
echo "Installing Sysbench..."
sudo apt-get install -y sysbench
sudo systemctl start mysql
sudo systemctl enable mysql
echo ""
echo "Configuring MySQL..."
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS sbtest;
CREATE USER IF NOT EXISTS 'sbtest'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON sbtest.* TO 'sbtest'@'localhost';
FLUSH PRIVILEGES;
EOF
echo ""
echo "Optimizing MySQL configuration..."
sudo tee /etc/mysql/mysql.conf.d/benchmark.cnf > /dev/null <<EOF
[mysqld]
innodb_buffer_pool_size = 2G
innodb_log_file_size = 512M
innodb_log_buffer_size = 16M
max_connections = 200
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
skip-log-bin
EOF
echo "Restarting MySQL..."
sudo systemctl restart mysql
echo ""
echo "Verifying installation..."
mysql --version
sysbench --version
echo ""
echo "✓ MySQL setup completed!"
echo "  Database: sbtest"
echo "  User: sbtest"
echo "  Password: password"