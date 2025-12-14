#!/bin/bash
set -e
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_DIR="../../results/nginx"
mkdir -p $RESULT_DIR
echo "=========================================="
echo "Nginx Performance Benchmark"
echo "Instance: $INSTANCE_TYPE"
echo "Timestamp: $TIMESTAMP"
echo "=========================================="
DURATION="60s"
THREADS=4
FILES="static/1kb.html static/10kb.html static/100kb.html"
CONNECTIONS_LIST="100 500 1000"
for TEST_FILE in $FILES; do
    FILE_SIZE=$(echo $TEST_FILE | cut -d'/' -f2)
    TARGET_URL="http://localhost/$TEST_FILE"
    echo ""
    echo "------------------------------------------------"
    echo "Testing Target: $FILE_SIZE"
    echo "------------------------------------------------"
    for CONNECTIONS in $CONNECTIONS_LIST; do
        echo "Running: $CONNECTIONS connections, $THREADS threads, duration $DURATION..."
        OUTPUT_JSON="$RESULT_DIR/nginx_${INSTANCE_TYPE}_${FILE_SIZE}_${CONNECTIONS}c_${TIMESTAMP}.json"
        TEMP_TXT="/tmp/wrk_output.txt"
        wrk -t$THREADS -c$CONNECTIONS -d$DURATION --latency $TARGET_URL > $TEMP_TXT
        RPS=$(grep "Requests/sec:" $TEMP_TXT | awk '{print $2}')
        TRANSFER=$(grep "Transfer/sec:" $TEMP_TXT | awk '{print $2}')
        LATENCY_AVG=$(grep "Latency" $TEMP_TXT | head -1 | awk '{print $2}')
        LATENCY_STDEV=$(grep "Latency" $TEMP_TXT | head -1 | awk '{print $3}')
        LATENCY_MAX=$(grep "Latency" $TEMP_TXT | head -1 | awk '{print $4}')
        echo "  -> RPS: $RPS"
        echo "  -> Transfer: $TRANSFER"
        echo "  -> Avg Latency: $LATENCY_AVG"
        cat > $OUTPUT_JSON <<EOF
{
  "instance_type": "$INSTANCE_TYPE",
  "timestamp": "$TIMESTAMP",
  "target_file": "$TEST_FILE",
  "connections": $CONNECTIONS,
  "threads": $THREADS,
  "duration": "$DURATION",
  "requests_per_sec": "$RPS",
  "transfer_per_sec": "$TRANSFER",
  "latency_avg": "$LATENCY_AVG",
  "latency_stdev": "$LATENCY_STDEV",
  "latency_max": "$LATENCY_MAX"
}
EOF
        echo "  Saved result to: $OUTPUT_JSON"
    done
done
echo ""
echo "=========================================="
echo "✓ All benchmarks completed successfully!"
echo "=========================================="