#!/bin/bash
RESULT_DIR="./results/network"
mkdir -p $RESULT_DIR
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$RESULT_DIR/network_${INSTANCE_TYPE}_${TIMESTAMP}.json"
echo "=========================================="
echo "Network Benchmark Test"
echo "Instance: $INSTANCE_TYPE"
echo "=========================================="
if [ "$1" == "server" ]; then
    echo "Starting iperf3 server mode..."
    iperf3 -s
    exit 0
fi
if [ -z "$1" ]; then
    echo "Usage: $0 <server_ip> OR $0 server"
    exit 1
fi
SERVER_IP=$1
echo "Testing connection to: $SERVER_IP"
for PARALLEL in 1 4 8; do
    echo ""
    echo "Testing with $PARALLEL parallel streams..."
    iperf3 -c $SERVER_IP \
        -t 30 \
        -P $PARALLEL \
        -J > /tmp/iperf3_${PARALLEL}.json
    BANDWIDTH=$(jq '.end.sum_received.bits_per_second' /tmp/iperf3_${PARALLEL}.json)
    BANDWIDTH_MBPS=$(echo "scale=2; $BANDWIDTH / 1000000" | bc)
    echo "  Bandwidth: ${BANDWIDTH_MBPS} Mbps"
    echo "{
  \"instance_type\": \"$INSTANCE_TYPE\",
  \"timestamp\": \"$TIMESTAMP\",
  \"parallel_streams\": $PARALLEL,
  \"bandwidth_mbps\": $BANDWIDTH_MBPS,
  \"server\": \"$SERVER_IP\"
}" >> $OUTPUT_FILE
done
echo ""
echo "Testing UDP throughput..."
iperf3 -c $SERVER_IP \
    -u \
    -b 1G \
    -t 30 \
    -J > /tmp/iperf3_udp.json
UDP_BW=$(jq '.end.sum.bits_per_second' /tmp/iperf3_udp.json)
UDP_BW_MBPS=$(echo "scale=2; $UDP_BW / 1000000" | bc)
PACKET_LOSS=$(jq '.end.sum.lost_percent' /tmp/iperf3_udp.json)
echo "  UDP Bandwidth: ${UDP_BW_MBPS} Mbps"
echo "  Packet Loss: ${PACKET_LOSS}%"
echo ""
echo "✓ Network benchmark completed!"
echo "Results saved to: $OUTPUT_FILE"