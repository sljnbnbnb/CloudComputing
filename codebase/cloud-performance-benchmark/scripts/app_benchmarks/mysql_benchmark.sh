cat > scripts/app_benchmarks/mysql_benchmark.sh << 'EOF'
set -e
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_DIR="./results/mysql"
mkdir -p $RESULT_DIR
echo "=========================================="
echo "MySQL Performance Benchmark"
echo "Instance: $INSTANCE_TYPE"
echo "=========================================="
TABLES=10
TABLE_SIZE=100000
THREADS_LIST="1 2 4 8"
TEST_DURATION=180
echo "Preparing test database..."
sysbench oltp_read_write \
    --mysql-host=localhost \
    --mysql-user=sbtest \
    --mysql-password=password \
    --mysql-db=sbtest \
    --tables=$TABLES \
    --table-size=$TABLE_SIZE \
    prepare
for THREADS in $THREADS_LIST; do
    echo ""
    echo "Testing with $THREADS threads..."
    sysbench oltp_read_write \
        --mysql-host=localhost \
        --mysql-user=sbtest \
        --mysql-password=password \
        --mysql-db=sbtest \
        --tables=$TABLES \
        --table-size=$TABLE_SIZE \
        --threads=$THREADS \
        --time=$TEST_DURATION \
        --report-interval=30 \
        run > /tmp/mysql_${THREADS}t.txt 2>&1
    TPS=$(grep "transactions:" /tmp/mysql_${THREADS}t.txt | awk '{print $3}' | sed 's/(//' || echo "0")
    QPS=$(grep "queries:" /tmp/mysql_${THREADS}t.txt | awk '{print $3}' | sed 's/(//' || echo "0")
    LATENCY_AVG=$(grep "avg:" /tmp/mysql_${THREADS}t.txt | head -1 | awk '{print $2}' || echo "0")
    echo "  TPS: $TPS"
    echo "  QPS: $QPS"
    echo "  Latency: ${LATENCY_AVG}ms"
    OUTPUT_FILE="$RESULT_DIR/mysql_${INSTANCE_TYPE}_${THREADS}t_${TIMESTAMP}.json"
    cat > $OUTPUT_FILE <<RESULT_EOF
{"instance_type":"$INSTANCE_TYPE","timestamp":"$TIMESTAMP","threads":$THREADS,"tps":$TPS,"qps":$QPS,"latency_avg_ms":$LATENCY_AVG}
RESULT_EOF
done
sysbench oltp_read_write \
    --mysql-host=localhost \
    --mysql-user=sbtest \
    --mysql-password=password \
    --mysql-db=sbtest \
    --tables=$TABLES \
    cleanup > /dev/null 2>&1
echo ""
echo "✓ Benchmark completed!"
EOF
chmod +x scripts/app_benchmarks/mysql_benchmark.sh