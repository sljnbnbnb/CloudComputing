#!/bin/bash
RESULT_DIR="./results/disk"
mkdir -p $RESULT_DIR
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$RESULT_DIR/disk_${INSTANCE_TYPE}_${TIMESTAMP}.json"
echo "=========================================="
echo "Disk I/O Benchmark Test"
echo "Instance: $INSTANCE_TYPE"
echo "=========================================="
declare -a IO_TESTS=("randread" "randwrite" "read" "write")
declare -a BLOCK_SIZES=("4k" "64k" "1m")
for IO_TYPE in "${IO_TESTS[@]}"; do
    for BS in "${BLOCK_SIZES[@]}"; do
        echo ""
        echo "Testing: $IO_TYPE with block size $BS"
        fio --name=test \
            --ioengine=libaio \
            --rw=$IO_TYPE \
            --bs=$BS \
            --size=1G \
            --numjobs=4 \
            --runtime=30 \
            --time_based \
            --direct=1 \
            --iodepth=64 \
            --output-format=json \
            --output=/tmp/fio_${IO_TYPE}_${BS}.json
        IOPS=$(jq '.jobs[0].read.iops + .jobs[0].write.iops' /tmp/fio_${IO_TYPE}_${BS}.json)
        BW=$(jq '.jobs[0].read.bw + .jobs[0].write.bw' /tmp/fio_${IO_TYPE}_${BS}.json)
        echo "  IOPS: $IOPS"
        echo "  Bandwidth: $BW KB/s"
        echo "{
  \"instance_type\": \"$INSTANCE_TYPE\",
  \"timestamp\": \"$TIMESTAMP\",
  \"io_type\": \"$IO_TYPE\",
  \"block_size\": \"$BS\",
  \"iops\": $IOPS,
  \"bandwidth_kbs\": $BW
}" >> $OUTPUT_FILE
    done
done
echo ""
echo "✓ Disk I/O benchmark completed!"
echo "Results saved to: $OUTPUT_FILE"