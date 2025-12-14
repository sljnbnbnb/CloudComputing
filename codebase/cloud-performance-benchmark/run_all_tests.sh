#!/bin/bash
echo "=========================================="
echo "Cloud Performance Benchmark Suite"
echo "=========================================="
echo ""
mkdir -p results/{cpu,memory,disk,network}
mkdir -p logs
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="logs/benchmark_${INSTANCE_TYPE}_${TIMESTAMP}.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1
echo "Instance Type: $INSTANCE_TYPE"
echo "Start Time: $(date)"
echo ""
run_test() {
    local test_name=$1
    local script=$2
    echo "=========================================="
    echo "Running $test_name..."
    echo "=========================================="
    if [ -f "$script" ]; then
        bash $script
        if [ $? -eq 0 ]; then
            echo "✓ $test_name completed successfully"
        else
            echo "✗ $test_name failed"
        fi
    else
        echo "✗ Script not found: $script"
    fi
    echo ""
}
run_test "CPU Benchmark" "scripts/cpu_benchmark.sh"
run_test "Memory Benchmark" "scripts/memory_benchmark.sh"
run_test "Disk I/O Benchmark" "scripts/disk_benchmark.sh"
echo "=========================================="
echo "Network Test Instructions"
echo "=========================================="
echo "To run network tests:"
echo "1. On another instance, run: bash scripts/network_benchmark.sh server"
echo "2. On this instance, run: bash scripts/network_benchmark.sh <server_ip>"
echo ""
echo "=========================================="
echo "Benchmark Suite Completed"
echo "End Time: $(date)"
echo "=========================================="
echo ""
echo "Results are saved in the ./results directory"
echo "Log file: $LOG_FILE"