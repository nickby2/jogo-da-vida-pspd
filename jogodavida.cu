#include <stdio.h>
#include <stdlib.h>
#include <cuda.h>

#define ind2d(i, j, tam) ((i) * (tam + 2) + (j))

__global__ void UmaVidaKernel(int* tabulIn, int* tabulOut, int tam) {
    int i = blockIdx.y * blockDim.y + threadIdx.y + 1;
    int j = blockIdx.x * blockDim.x + threadIdx.x + 1;

    if (i <= tam && j <= tam) {
        int vizviv = tabulIn[ind2d(i-1, j-1, tam)] + tabulIn[ind2d(i-1, j  , tam)] +
                     tabulIn[ind2d(i-1, j+1, tam)] + tabulIn[ind2d(i  , j-1, tam)] +
                     tabulIn[ind2d(i  , j+1, tam)] + tabulIn[ind2d(i+1, j-1, tam)] +
                     tabulIn[ind2d(i+1, j  , tam)] + tabulIn[ind2d(i+1, j+1, tam)];

        if (tabulIn[ind2d(i, j, tam)] && vizviv < 2)
            tabulOut[ind2d(i, j, tam)] = 0;
        else if (tabulIn[ind2d(i, j, tam)] && vizviv > 3)
            tabulOut[ind2d(i, j, tam)] = 0;
        else if (!tabulIn[ind2d(i, j, tam)] && vizviv == 3)
            tabulOut[ind2d(i, j, tam)] = 1;
        else
            tabulOut[ind2d(i, j, tam)] = tabulIn[ind2d(i, j, tam)];
    }
}

void UmaVida(int* d_in, int* d_out, int tam) {
    dim3 threadsPerBlock(16, 16);
    dim3 numBlocks((tam + 15) / 16, (tam + 15) / 16);
    UmaVidaKernel<<<numBlocks, threadsPerBlock>>>(d_in, d_out, tam);
    cudaDeviceSynchronize();
}

void InicializaTabuleiro(int* tabul, int tam) {
    for (int i = 0; i < (tam + 2) * (tam + 2); i++) {
        tabul[i] = rand() % 2;
    }
}

int main() {
    int tam = 32;
    int maxGen = 100;

    size_t size = (tam + 2) * (tam + 2) * sizeof(int);

    int* h_tabul1 = (int*)malloc(size);
    int* h_tabul2 = (int*)malloc(size);

    InicializaTabuleiro(h_tabul1, tam);

    int* d_tabul1;
    int* d_tabul2;

    cudaMalloc((void**)&d_tabul1, size);
    cudaMalloc((void**)&d_tabul2, size);

    cudaMemcpy(d_tabul1, h_tabul1, size, cudaMemcpyHostToDevice);

    FILE* arquivo = fopen("geracoes.txt", "w");

    cudaEvent_t start, stop;
    float milliseconds = 0;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);

    for (int gen = 0; gen < maxGen; gen++) {
        UmaVida(d_tabul1, d_tabul2, tam);

        cudaMemcpy(h_tabul1, d_tabul1, size, cudaMemcpyDeviceToHost);

        fprintf(arquivo, "Geração %d:\n", gen + 1);
        for (int i = 1; i <= tam; i++) {
            for (int j = 1; j <= tam; j++) {
                fprintf(arquivo, "%d ", h_tabul1[ind2d(i, j, tam)]);
            }
            fprintf(arquivo, "\n");
        }
        fprintf(arquivo, "\n");

        int* temp = d_tabul1;
        d_tabul1 = d_tabul2;
        d_tabul2 = temp;
    }

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&milliseconds, start, stop);

    cudaMemcpy(h_tabul1, d_tabul1, size, cudaMemcpyDeviceToHost);

    printf("Simulação completa!\n");
    printf("Tempo de execução na GPU: %.4f ms\n", milliseconds);

    fclose(arquivo);
    cudaFree(d_tabul1);
    cudaFree(d_tabul2);
    free(h_tabul1);
    free(h_tabul2);

    return 0;
}
