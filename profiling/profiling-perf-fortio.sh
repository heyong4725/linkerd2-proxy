#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

PROFDIR=$(dirname "$0")

source "$PROFDIR/profiling-util.sh"

status "Starting" "perf profile ${RUN_NAME}"

cd "$PROFDIR"

# Cleanup background processes when script is canceled
trap '{ teardown; }' EXIT

# Summary table header
echo "Test, target req/s, req len, branch, p999 latency (ms), GBit/s" > "$OUT_DIR/summary.txt"

export PROXY_PERF=1;

if [ "$TCP" -eq "1" ]; then
  MODE=TCP DIRECTION=outbound NAME=tcpoutbound_bench PROXY_PORT=$PROXY_PORT_OUTBOUND SERVER_PORT=5001 single_benchmark_run
  MODE=TCP DIRECTION=inbound NAME=tcpinbound_bench PROXY_PORT=$PROXY_PORT_INBOUND SERVER_PORT=5001 single_benchmark_run
fi
if [ "$HTTP" -eq "1" ]; then
  MODE=HTTP DIRECTION=outbound NAME=http1outbound_bench PROXY_PORT=$PROXY_PORT_OUTBOUND SERVER_PORT=8080 single_benchmark_run
  MODE=HTTP DIRECTION=inbound NAME=http1inbound_bench PROXY_PORT=$PROXY_PORT_INBOUND SERVER_PORT=8080 single_benchmark_run
fi
if [ "$GRPC" -eq "1" ]; then
  MODE=gRPC DIRECTION=outbound NAME=grpcoutbound_bench PROXY_PORT=$PROXY_PORT_OUTBOUND SERVER_PORT=8079 single_benchmark_run
  MODE=gRPC DIRECTION=inbound NAME=grpcinbound_bench PROXY_PORT=$PROXY_PORT_INBOUND SERVER_PORT=8079 single_benchmark_run
fi
teardown

status "Completed" "Log files (display with 'head -vn-0 *$ID.txt *$ID.json | less'):"
ls "$OUT_DIR/*.txt" "$OUT_DIR/*.json"
echo SUMMARY:
cat "$OUT_DIR/summary.txt"
status "Completed" "inspect flamegraphs in browser:"
ls "$OUT_DIR/*.svg"

