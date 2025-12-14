#!/bin/bash
echo "=========================================="
echo "Cloud Performance Benchmark Setup"
echo "=========================================="
echo "[1/5] Updating system packages..."
sudo apt-get update -y
echo "[2/5] Installing Sysbench..."
sudo apt-get install -y sysbench
echo "[3/5] Installing FIO..."
sudo apt-get install -y fio
echo "[4/5] Installing iperf3..."
sudo apt-get install -y iperf3
echo "[4.5/5] Installing Nginx & wrk..."
sudo apt-get install -y nginx wrk
echo "[5/5] Installing utilities..."
sudo apt-get install -y wget curl jq bc unzip git build-essential
echo ""
echo "=========================================="
echo "Verification:"
echo "=========================================="
echo "Sysbench version: $(sysbench --version)"
echo "FIO version: $(fio --version)"
echo "iperf3 version: $(iperf3 --version)"
echo ""
echo "✓ Setup completed successfully!"
echo "You can now run the benchmark tests."