#!/usr/bin/bash
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
YELLOW='\e[33m'
NC='\e[0m' # No Color (reset)

NUM_RUNS=1
LONGOPTS=help,num-runs:,version
OPTIONS=n:hv

help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -n, --num-runs <number>  Number of runs for each implementation (default: 1)"
  echo "  -h, --help    Show this help message"
  echo "  -v, --version Show script version"
}

start_spinner() {
  local spin='-\|/'
  local pid="$1"
  local i=0
  while kill -0 "$pid" 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1}"
    sleep .1
  done
  printf "\r"
}

version() {
  echo "Performance Test Script Version 1.1"
}

PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@") || exit 2

eval set -- "$PARSED"

BUILD_DIR=./build
declare -a execs=("jogodavida" "jogodavidaomp" "jogodavidaomp-gpu" "jogodavida_mpi" "jogodavida_cuda")

while true; do
  case "$1" in
    -h|--help)
      help
      exit 0
      ;;
    -v|--version)
      version
      exit 0
      ;;
    -n|--num-runs)
      NUM_RUNS="$2"
      shift 2
      ;;
    --) 
      shift
      break
      ;;
    *) 
      echo "Invalid option: $1" >&2
      exit 1
      ;;
  esac
done

echo "--- Performance Test Script ---"
echo "Please ensure that the implementations are running correctly befure running the performance tests."

echo "Building implementations..."
result=$(make all)
if grep -qi "nothing to be done" <<< "$result"; then
    echo -e "${GREEN}All scripts built${NC}" 1>&2
else 
  echo -e "${YELLOW}$result${NC}" 1>&2
fi

trap 'rm -f "$temp_file" "$comparison_file" "$temp_avg_file"' EXIT

echo "======= Running performance tests...  ======="
echo "============================================="

temp_file=$(mktemp /tmp/perf_test.XXXXXX)
comparison_file=$(mktemp /tmp/perf_comparison.XXXXXX)
temp_avg_file=$(mktemp /tmp/perf_avg.XXXXXX)
total_time_taken=0
for exec in "${execs[@]}"; do
  if [[ ! -f "$BUILD_DIR/$exec" ]]; then
    echo -e "${RED}Error: $exec not found in $BUILD_DIR${NC}" 1>&2
    continue
  fi

  : > "$temp_avg_file"
  echo "---- Running $exec ($NUM_RUNS runs) ----"
  for ((i=0; i<NUM_RUNS; i++)); do
    echo -e "${YELLOW}Run $((i+1)) of $NUM_RUNS for $exec...${NC}"
    if [[ "$exec" == *"mpi"* ]]; then
        command time -f "%e" mpirun -np "$(nproc)" "$BUILD_DIR/$exec" > /dev/null 2>>"$temp_avg_file" &
    else
        command time -f "%e" "$BUILD_DIR/$exec" > /dev/null 2>>"$temp_avg_file" &
    fi
    pid=$!
    start_spinner "$pid"
    wait "$pid"
    echo -e "${BLUE}Execution time for $exec in run $i: $(tail -n 1 "$temp_avg_file")s${NC}"
  done
    
  runtime=$(awk '{ total += $1; count++ } END { if (count > 0) print total / count; else print 0 }' "$temp_avg_file")
  total_time_taken=$(echo "$total_time_taken + $runtime" | bc -l)
  echo -e "${BLUE}Average execution time for $exec in $NUM_RUNS runs: ${runtime}s${NC}"
  echo "$exec $runtime" >> "$comparison_file"
done

echo "============================================="

if [ -s "$comparison_file" ]; then
    echo "======= Performance tests results...  ======="
    echo "Total time taken for all runs: ${total_time_taken}s"
    
    base_time=""
    while read -r exec time; do
        if [[ "$exec" == "jogodavida" ]]; then
            base_time="$time"
            echo -e "$exec: ${time}s (baseline)"
            break
        fi
    done < "$comparison_file"
    
    if [ -z "$base_time" ]; then
        echo -e "${RED}Error: No baseline (jogodavida) result found${NC}" >&2
        exit 1
    fi
    
    while read -r exec time; do
        if [[ "$exec" == "jogodavida" ]]; then
            continue
        fi
        speedup=$(echo "scale=2; $base_time / $time" | bc -l)
        
        if (( $(echo "$speedup > 1" | bc -l) )); then
            echo -e "${GREEN}$exec: ${time}s (${speedup}x speedup)${NC}"
        elif (( $(echo "$speedup < 1" | bc -l) )); then
            slowdown=$(echo "scale=2; $time / $base_time" | bc -l)
            echo -e "${RED}$exec: ${time}s (${slowdown}x slower)${NC}"
        else
            echo -e "$exec: ${time}s (same speed)"
        fi
    done < "$comparison_file"
else
    echo -e "${RED}No performance results to compare${NC}" >&2
fi
