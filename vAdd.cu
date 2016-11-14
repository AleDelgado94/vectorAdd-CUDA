#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <time.h>

__global__ void vAdd(int* A, int* B, int* C, int num_elements){

	//Posicion del thread
	int i = blockIdx.x * blockDim.x + threadIdx.x;

	if(i < num_elements){
		C[i] = A[i] + B[i];
	}


}


void sumarVectores(int* A, int* B, int* C, int num_elements){
	//Posicion del thread
	//int i = blockIdx.x * blockDim.x + threadIdx.x;


	for(int i=0; i<num_elements; i++){
		C[i] = A[i] + B[i];
	}
}


int main(){

	int num_elements = 100000;

	//Reservar espacio en memoria HOST


	int * h_A = (int*)malloc(num_elements * sizeof(int));
	int * h_B = (int*)malloc(num_elements * sizeof(int));
	int * h_C = (int*)malloc(num_elements * sizeof(int));



	//Inicializar elementos de los vectores
	for(int i=0; i<num_elements; i++){
		h_A[i] = 1;
		h_B[i] = i;
	}

	cudaError_t err;

	int size = num_elements * sizeof(int);

	int * d_A = NULL;
	err = cudaMalloc((void **)&d_A, size);

	int * d_B = NULL;
	err = cudaMalloc((void **)&d_B, size);

	int * d_C = NULL;
	err = cudaMalloc((void **)&d_C, size);

	//Copiamos a GPU DEVICE
	err = cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
	err = cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);
	err = cudaMemcpy(d_C, h_C, size, cudaMemcpyHostToDevice);

	int HilosPorBloque = 512;
	int BloquesPorGrid = (num_elements + HilosPorBloque -1) / HilosPorBloque;


	//Lanzamos el kernel y medimos tiempos
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start, 0);

	vAdd<<<BloquesPorGrid, HilosPorBloque>>>(d_A, d_B, d_C, num_elements);

	cudaEventRecord(stop,0);
	cudaEventSynchronize(stop);
	float tiempo_reserva_host;
	cudaEventElapsedTime(&tiempo_reserva_host, start, stop);


	printf("Tiempo de suma vectores DEVICE: %f\n", tiempo_reserva_host);

	cudaEventDestroy(start);
	cudaEventDestroy(stop);


	//Copiamos a CPU el vector C
	err = cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);



	//Realizamos la suma en la CPU
	cudaEvent_t start1, stop1;
	cudaEventCreate(&start1);
	cudaEventCreate(&stop1);

	cudaEventRecord(start1, 0);

	sumarVectores(h_A, h_B, h_C, num_elements);

	cudaEventRecord(stop1,0);
	cudaEventSynchronize(stop1);
	float tiempo_reserva_host1;
	cudaEventElapsedTime(&tiempo_reserva_host1, start1, stop1);


	printf("Tiempo de suma vectores HOST: %f\n", tiempo_reserva_host1);

	cudaEventDestroy(start1);
	cudaEventDestroy(stop1);

	/*for(int i=0; i<num_elements; i++){
		printf("%i", h_C[i]);
		printf("\n");
	}*/

}







