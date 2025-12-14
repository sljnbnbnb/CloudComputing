#!/bin/bash
RESULT_DIR="./results/memory"
mkdir -p $RESULT_DIR
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$RESULT_DIR/memory_${INSTANCE_TYPE}_${TIMESTAMP}.json"
echo "=========================================="
echo "Memory Benchmark Test"
echo "Instance: $INSTANCE_TYPE"
echo "=========================================="
CPU_COUNT=$(nproc)
for OPERATION in read write; do
    echo ""
    echo "Testing $OPERATION operation..."
    sysbench memory \
        --threads=$CPU_COUNT \
        --memory-total-size=10G \
        --memory-oper=$OPERATION \
        --memory-scope=global \
        run > /tmp/memory_${OPERATION}.txt
    BANDWIDTH=$(grep "transferred" /tmp/memory_${OPERATION}.txt | awk '{print $(NF-1)}')
    echo "  Bandwidth: $BANDWIDTH MiB/sec"
    echo "{
  \"instance_type\": \"$INSTANCE_TYPE\",
  \"timestamp\": \"$TIMESTAMP\",
  \"operation\": \"$OPERATION\",
  \"bandwidth_mibs\": $BANDWIDTH,
  \"threads\": $CPU_COUNT
}" >> $OUTPUT_FILE
done
echo ""
echo "✓ Memory benchmark completed!"
echo "Results saved to: $OUTPUT_FILE"