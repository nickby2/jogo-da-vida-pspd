CC=gcc
CFLAGS=-Wall -Wextra -pedantic

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
	@echo "  jogodavida_mpi      - Build MPI distributed version"
	@echo "  jogodavida_cuda     - Build CUDA GPU version"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean               - Remove build directory and all binaries"
	@echo "  help                - Show this help message"
	@echo ""
	@echo "Current variables:"
	@echo " CC=$(CC)"
	@echo " NVCC=$(NVCC)"
	@echo " MPICC=$(MPICC)"
	@echo " CFLAGS=$(CFLAGS)"
	@echo " BUILD_DIR=$(BUILD_DIR)"

all: jogodavida jogodavidaomp jogodavidaomp-gpu jogodavida_mpi jogodavida_cuda

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/jogodavida: jogodavida.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/jogodavidaomp: jogodavidaomp.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -fopenmp -o $@ $<

$(BUILD_DIR)/jogodavidaomp-gpu: jogodavidaomp-gpu.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -fopenmp -o $@ $<

$(BUILD_DIR)/jogodavida_mpi: jogodavidampi.c | $(BUILD_DIR)
	$(MPICC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/jogodavida_cuda: jogodavida.cu | $(BUILD_DIR)
	$(NVCC) -Wno-deprecated-gpu-targets -o $@ $<

jogodavida: $(BUILD_DIR)/jogodavida 
jogodavidaomp: $(BUILD_DIR)/jogodavidaomp 
jogodavidaomp-gpu: $(BUILD_DIR)/jogodavidaomp-gpu 
jogodavida_mpi: $(BUILD_DIR)/jogodavida_mpi
jogodavida_cuda: $(BUILD_DIR)/jogodavida_cuda

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean help jogodavida jogodavidaomp jogodavidaomp-gpu jogodavida_mpi jogodavida_cuda
