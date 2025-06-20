#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

#define ind2d(i, j, tam) ((i) * (tam + 2) + (j))

void InicializaTabuleiro(int* tabul, int tam) {
    for (int i = 0; i < (tam + 2) * (tam + 2); i++) {
        tabul[i] = rand() % 2;
    }
}

void UmaVidaSerial(int* in, int* out, int tam, int start, int end) {
    for (int i = start; i <= end; i++) {
        for (int j = 1; j <= tam; j++) {
            int vizviv = in[ind2d(i-1, j-1, tam)] + in[ind2d(i-1, j  , tam)] +
                         in[ind2d(i-1, j+1, tam)] + in[ind2d(i  , j-1, tam)] +
                         in[ind2d(i  , j+1, tam)] + in[ind2d(i+1, j-1, tam)] +
                         in[ind2d(i+1, j  , tam)] + in[ind2d(i+1, j+1, tam)];

            if (in[ind2d(i, j, tam)] && vizviv < 2)
                out[ind2d(i, j, tam)] = 0;
            else if (in[ind2d(i, j, tam)] && vizviv > 3)
                out[ind2d(i, j, tam)] = 0;
            else if (!in[ind2d(i, j, tam)] && vizviv == 3)
                out[ind2d(i, j, tam)] = 1;
            else
                out[ind2d(i, j, tam)] = in[ind2d(i, j, tam)];
        }
    }
}

void ExportaGeracao(FILE* f, int* tab, int tam, int gen) {
    fprintf(f, "Geração %d:\n", gen);
    for (int i = 1; i <= tam; i++) {
        for (int j = 1; j <= tam; j++) {
            fprintf(f, "%d ", tab[ind2d(i, j, tam)]);
        }
        fprintf(f, "\n");
    }
    fprintf(f, "\n");
}

int main(int argc, char** argv) {
    int tam = 32;
    int maxGen = 100;

    int rank, size;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    size_t totalSize = (tam + 2) * (tam + 2);
    int* globalTab = NULL;
    int* newGlobalTab = NULL;
    FILE* f = NULL;

    if (rank == 0) {
        globalTab = (int*)malloc(totalSize * sizeof(int));
        newGlobalTab = (int*)malloc(totalSize * sizeof(int));
        InicializaTabuleiro(globalTab, tam);
        f = fopen("saida_mpi.txt", "w");
    }

    int rowsPerProc = tam / size;
    int remainder = tam % size;
    int localRows = rowsPerProc + (rank < remainder ? 1 : 0);
    int startRow = rank * rowsPerProc + (rank < remainder ? rank : remainder) + 1;
    int endRow = startRow + localRows - 1;
    int localSize = (localRows + 2) * (tam + 2);
    int* localIn = (int*)malloc(localSize * sizeof(int));
    int* localOut = (int*)malloc(localSize * sizeof(int));

    double startTime = MPI_Wtime();

    for (int gen = 1; gen <= maxGen; gen++) {
        if (rank == 0) {
            for (int p = 1; p < size; p++) {
                int pStartRow = p * rowsPerProc + (p < remainder ? p : remainder) + 1;
                int pLocalRows = rowsPerProc + (p < remainder ? 1 : 0);
                MPI_Send(&globalTab[ind2d(pStartRow - 1, 0, tam)], (pLocalRows + 2) * (tam + 2), MPI_INT, p, 0, MPI_COMM_WORLD);
            }
            for (int i = 0; i < (localRows + 2) * (tam + 2); i++) {
                localIn[i] = globalTab[ind2d(startRow - 1, 0, tam) + i];
            }
        } else {
            MPI_Recv(localIn, (localRows + 2) * (tam + 2), MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        }

        UmaVidaSerial(localIn, localOut, tam, 1, localRows);

        if (rank == 0) {
            for (int i = 1; i <= localRows; i++) {
                for (int j = 0; j < tam + 2; j++) {
                    newGlobalTab[ind2d(startRow + i - 1, j, tam)] = localOut[ind2d(i, j, tam)];
                }
            }
            for (int p = 1; p < size; p++) {
                int pStartRow = p * rowsPerProc + (p < remainder ? p : remainder) + 1;
                int pLocalRows = rowsPerProc + (p < remainder ? 1 : 0);
                MPI_Recv(&newGlobalTab[ind2d(pStartRow, 0, tam)], pLocalRows * (tam + 2), MPI_INT, p, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            }
            int* temp = globalTab;
            globalTab = newGlobalTab;
            newGlobalTab = temp;
            ExportaGeracao(f, globalTab, tam, gen);
        } else {
            MPI_Send(&localOut[ind2d(1, 0, tam)], localRows * (tam + 2), MPI_INT, 0, 1, MPI_COMM_WORLD);
        }
    }

    double endTime = MPI_Wtime();

    if (rank == 0) {
        fclose(f);
        printf("Simulação MPI completa!\n");
        printf("Tempo de execução: %f segundos\n", endTime - startTime);
        free(globalTab);
        free(newGlobalTab);
    }

    free(localIn);
    free(localOut);
    MPI_Finalize();
    return 0;
}
