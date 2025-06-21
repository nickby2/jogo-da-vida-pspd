#!/bin/bash

# Script de teste para Jogo da Vida OpenMP com GPU
# Verifica se a GPU está disponível e compara performance

echo "=== Teste do Jogo da Vida OpenMP com GPU ==="
echo

# Verifica se o executável existe
if [ ! -f "jogodavidaomp-gpu" ]; then
    echo "Compilando o programa..."
    make jogodavidaomp-gpu
fi

# Verifica se a compilação foi bem-sucedida
if [ ! -f "jogodavidaomp-gpu" ]; then
    echo "Erro: Falha na compilação!"
    exit 1
fi

echo "1. Verificando dispositivos OpenMP disponíveis..."
echo "----------------------------------------"
OMP_TARGET_OFFLOAD=MANDATORY ./jogodavidaomp-gpu 2>&1 | head -20
echo

echo "2. Teste de execução normal (CPU fallback se GPU não disponível)..."
echo "----------------------------------------"
./jogodavidaomp-gpu
echo

echo "3. Comparação de performance CPU vs GPU..."
echo "----------------------------------------"

# Compila versão CPU se não existir
if [ ! -f "jogodavidaomp-gpu-cpu" ]; then
    echo "Compilando versão CPU..."
    make jogodavidaomp-gpu-cpu
fi

# Teste com tamanho menor para comparação rápida
echo "Teste com tabuleiro 8x8 (2^3):"
echo "CPU:"
time ./jogodavidaomp-gpu-cpu 2>&1 | grep "tam=8"
echo "GPU:"
time ./jogodavidaomp-gpu 2>&1 | grep "tam=8"
echo

echo "4. Verificando variáveis de ambiente OpenMP..."
echo "----------------------------------------"
echo "OMP_TARGET_OFFLOAD: ${OMP_TARGET_OFFLOAD:-não definido}"
echo "OMP_NUM_TEAMS: ${OMP_NUM_TEAMS:-não definido}"
echo "OMP_TEAMS_THREAD_LIMIT: ${OMP_TEAMS_THREAD_LIMIT:-não definido}"
echo

echo "5. Informações do sistema..."
echo "----------------------------------------"
echo "Compilador GCC versão:"
gcc --version | head -1
echo
echo "OpenMP versão:"
gcc -fopenmp -dM -E - < /dev/null | grep -i openmp
echo

echo "6. Teste de stress (apenas se GPU estiver disponível)..."
echo "----------------------------------------"
echo "Executando com OMP_TARGET_OFFLOAD=MANDATORY..."
OMP_TARGET_OFFLOAD=MANDATORY timeout 30s ./jogodavidaomp-gpu 2>&1 | tail -10
echo

echo "=== Teste concluído ==="
echo
echo "Dicas para otimização:"
echo "- Para forçar uso da GPU: export OMP_TARGET_OFFLOAD=MANDATORY"
echo "- Para definir número de teams: export OMP_NUM_TEAMS=256"
echo "- Para definir threads por team: export OMP_TEAMS_THREAD_LIMIT=1024"
echo "- Para AMD ROCm: export HSA_ENABLE_SDMA=0"
echo "- Para NVIDIA: export CUDA_VISIBLE_DEVICES=0" 
