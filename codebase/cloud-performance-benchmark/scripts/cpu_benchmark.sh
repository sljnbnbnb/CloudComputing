#!/bin/bash
RESULT_DIR="./results/cpu"
mkdir -p $RESULT_DIR
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$RESULT_DIR/cpu_${INSTANCE_TYPE}_${TIMESTAMP}.json"
echo "=========================================="
echo "CPU Benchmark Test"
echo "Instance: $INSTANCE_TYPE"
echo "=========================================="
CPU_COUNT=$(nproc)
echo "CPU cores detected: $CPU_COUNT"
for THREADS in 1 2 4; do
    if [ $THREADS -le $CPU_COUNT ]; then
        echo ""
        echo "Testing with $THREADS thread(s)..."
        sysbench cpu \
            --threads=$THREADS \
            --cpu-max-prime=20000 \
            --time=60 \
            run > /tmp/cpu_result_${THREADS}.txt
        EVENTS=$(grep "events per second:" /tmp/cpu_result_${THREADS}.txt | awk '{print $4}')
        LATENCY_AVG=$(grep "avg:" /tmp/cpu_result_${THREADS}.txt | awk '{print $2}')
        echo "  Events/sec: $EVENTS"
        echo "  Avg Latency: ${LATENCY_AVG}ms"
        echo "{
  \"instance_type\": \"$INSTANCE_TYPE\",
  \"timestamp\": \"$TIMESTAMP\",
  \"threads\": $THREADS,
  \"events_per_second\": $EVENTS,
  \"avg_latency_ms\": $LATENCY_AVG
}" >> $OUTPUT_FILE
    fi
done
echo ""
echo "✓ CPU benchmark completed!"
echo "Results saved to: $OUTPUT_FILE"