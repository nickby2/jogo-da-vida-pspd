CC=gcc
CFLAGS=-Wall -Wextra -pedantic
OMP_FLAGS=-fopenmp
GPU_FLAGS=-foffload=amdgcn-amdhsa

# Fallback para sistemas sem suporte a GPU
GPU_FLAGS_FALLBACK=-fopenmp

NVCC=nvcc
MPICC=mpicc

BUILD_DIR=build

help:
	@echo "Game of Life - Parallel Implementations"
	@echo "=============================================="
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "Build targets:"
	@echo "  all                 - Build all implementations"
	@echo "  jogodavida          - Build serial version"
	@echo "  jogodavidaomp       - Build OpenMP parallel version"
	@echo "  jogodavidaomp-gpu   - Build OpenMP GPU offload version"
	@echo "  jogodavidaomp-gpu-fallback - Build OpenMP version (CPU fallback)"
	@echo "  jogodavida_mpi      - Build MPI distributed version"
	@echo "  jogodavida_cuda     - Build CUDA GPU version"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean               - Remove build directory and all binaries"
	@echo "  help                - Show this help message"
	@echo "  test-gpu            - Run GPU tests"
	@echo ""
	@echo "Current variables:"
	@echo " CC=$(CC)"
	@echo " NVCC=$(NVCC)"
	@echo " MPICC=$(MPICC)"
	@echo " CFLAGS=$(CFLAGS)"
	@echo " OMP_FLAGS=$(OMP_FLAGS)"
	@echo " GPU_FLAGS=$(GPU_FLAGS)"
	@echo " BUILD_DIR=$(BUILD_DIR)"

all: jogodavida jogodavidaomp jogodavidaomp-gpu-fallback jogodavida_mpi jogodavida_cuda

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/jogodavida: jogodavida.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/jogodavidaomp: jogodavidaomp.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(OMP_FLAGS) -o $@ $<

$(BUILD_DIR)/jogodavidaomp-gpu: jogodavidaomp-gpu.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(OMP_FLAGS) $(GPU_FLAGS) -o $@ $<

$(BUILD_DIR)/jogodavidaomp-gpu-fallback: jogodavidaomp-gpu.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(OMP_FLAGS) $(GPU_FLAGS_FALLBACK) -o $@ $<

$(BUILD_DIR)/jogodavida_mpi: jogodavidampi.c | $(BUILD_DIR)
	$(MPICC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/jogodavida_cuda: jogodavida.cu | $(BUILD_DIR)
	$(NVCC) -Wno-deprecated-gpu-targets -o $@ $<

jogodavida: $(BUILD_DIR)/jogodavida 
jogodavidaomp: $(BUILD_DIR)/jogodavidaomp 
jogodavidaomp-gpu: $(BUILD_DIR)/jogodavidaomp-gpu 
jogodavidaomp-gpu-fallback: $(BUILD_DIR)/jogodavidaomp-gpu-fallback
jogodavida_mpi: $(BUILD_DIR)/jogodavida_mpi
jogodavida_cuda: $(BUILD_DIR)/jogodavida_cuda

test-gpu: jogodavidaomp-gpu-fallback
	@echo "Running GPU tests..."
	./test_gpu.sh

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean help test-gpu jogodavida jogodavidaomp jogodavidaomp-gpu jogodavidaomp-gpu-fallback jogodavida_mpi jogodavida_cuda
