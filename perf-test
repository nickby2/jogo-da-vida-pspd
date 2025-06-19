#!/usr/bin/bash
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
YELLOW='\e[33m'
NC='\e[0m' # No Color (reset)

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

echo "--- Performance Test Script ---"
echo "Please ensure that the implementations are running correctly befure running the performance tests."

BUILD_DIR=./build
declare -a execs=("jogodavida" "jogodavidaomp" "jogodavidaomp-gpu" "jogodavida_mpi" "jogodavida_cuda")

echo "Building implementations..."
result=$(make all)
if grep -qi "nothing to be done" <<< "$result"; then
    echo -e "${GREEN}All scripts built${NC}" 1>&2
else 
  echo -e "${YELLOW}$result${NC}" 1>&2
fi

trap 'rm -f "$temp_file" "$comparison_file"' EXIT

echo "======= Running performance tests...  ======="
echo "============================================="

# TODO: adicionar tabela de comparação de resultados
temp_file=$(mktemp /tmp/perf_test.XXXXXX)
comparison_file=$(mktemp /tmp/perf_comparison.XXXXXX)
for exec in "${execs[@]}"; do
  if [[ ! -f "$BUILD_DIR/$exec" ]]; then
    echo -e "${RED}Error: $exec not found in $BUILD_DIR${NC}" 1>&2
    continue
  fi

  echo "Running $exec:"
  if [[ "$exec" == *"mpi"* ]]; then
      # NOTE: especificar qtd de cores
      command time -f "%e" mpirun -np 4 "$BUILD_DIR/$exec" > /dev/null 2>"$temp_file" &
  else
      command time -f "%e" "$BUILD_DIR/$exec" > /dev/null 2>"$temp_file" &
  fi
  pid=$!
  start_spinner "$pid"
  wait "$pid"
    
  runtime=$(cat "$temp_file")
  echo -e "${BLUE}Execution time for $exec: ${runtime}s${NC}"
  echo "$exec $runtime" >> "$comparison_file"
done
echo "============================================="

if [ -s "$comparison_file" ]; then
    echo "======= Performance tests results...  ======="
    
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
