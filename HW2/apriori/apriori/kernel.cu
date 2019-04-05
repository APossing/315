
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdlib.h>
#include <stdio.h>
#include "CUDABackground.h"
#include <pplinterface.h>
#include "FileReader2.h"
#include "UserTableReader.h"
#include <chrono>
#include <sstream>
using namespace std;

__global__ void centerMatrix(float*userArray, unsigned short *userArrayColumns, unsigned short *userArrayRows)
{
	short column = blockIdx.x * blockDim.x + threadIdx.x + 1; //0th column is empty on purpose
	float cur;
	if (column == 3)
		printf("");
	if (column < *userArrayColumns)
	{
		double total = 0;
		unsigned short count = 0;
		for (short i = 1; i < *userArrayRows; i++)
		{
			cur = userArray[i * (*userArrayColumns) + column];
			if (cur > 0 && cur <= 5)
			{
				total += cur;
				count++;
			}
		}
		float const average = total / count;
		userArray[column] = average;

		for (short i = 1; i < *userArrayRows; i++)
		{
			cur = userArray[i * (*userArrayColumns) + column];
			if (cur > 0 && cur <= 5)
			{
				userArray[i* (*userArrayColumns) + column] = cur - average;
			}
		}
	}
}


__global__ void loadTop5(float*userArray, unsigned short *userArrayRows, unsigned short *userArrayColumns, unsigned short *top5UserArray, unsigned short *top5UserArrayColumns, bool *didSelect)
{
	short const row = blockIdx.x * blockDim.x + threadIdx.x + 1;
	float biggest;
	short biggestIndex = 0;
	if (row < *userArrayRows)
	{
		for (short i = 0; i < *top5UserArrayColumns; i++)
		{
			for (short j = 1; j < *userArrayColumns; j++)
			{
				if (!didSelect[row * (*userArrayColumns) + j])
				{
					if (userArray[row * (*userArrayColumns) + j ] > biggest)
					{
						biggest = userArray[row * (*userArrayColumns) + j];
						biggestIndex = j;
					}
				}
			}
			if (biggestIndex == 0)
				return;
			top5UserArray[row * (*top5UserArrayColumns) + i] = biggestIndex;
			didSelect[row * (*userArrayColumns) + biggestIndex] = true;
			biggestIndex = 0;
			biggest = 0;
		}
	}
}

__global__ void computeSimularMoviesType2TEST(float*userArray, unsigned short *userArrayRows, float*movieArray, unsigned short *movieArrayColumns)
{
	short const movie1 = blockDim.x * blockIdx.x + threadIdx.x + 1;
	short const movie2 = blockDim.y * blockIdx.y + threadIdx.y + 1;
	if (movie1 < *movieArrayColumns && movie2 < *movieArrayColumns && movie1 > movie2)
	{
		for (short i = 1; i < *userArrayRows; i++)	//for every user
		{
			if (userArray[i* (*movieArrayColumns) + movie1] > 1)
				printf("(%d,%f)", i, userArray[i* (*movieArrayColumns) + movie1]);
		}
	}
}

__global__ void computeSimularMoviesType2(float*userArray, unsigned short *userArrayRows, float*movieArray, unsigned short *movieArrayColumns)
{
	short const movie1 = blockDim.x * blockIdx.x + threadIdx.x + 1;
	short const movie2 = blockDim.y * blockIdx.y + threadIdx.y + 1;

	if (movie1 < *movieArrayColumns && movie2 < *movieArrayColumns && movie1 > movie2)
	{
		//printf("%d,%d\n", movie1, movie2);
		double top = 0;
		float topLeft;
		float topRight;
		double bottomLeft = 0;
		double bottomRight = 0;
		for (short i = 1; i < (*userArrayRows); i++)	//for every user
		{
			topLeft = userArray[i* (*movieArrayColumns) + movie1];			//get user rating for movie 1

			topRight = userArray[i* (*movieArrayColumns) + movie2]; 		//get user rating for movie 2					

			top += topRight * topLeft;										//compute this one and add to sum

			bottomLeft += topLeft * topLeft;								//A^2 and add to A's sum
			bottomRight += topRight * topRight;								//B^2 and add to B's sum				
		}

		if (bottomLeft == 0 || bottomRight == 0)
		{
			movieArray[movie1* (*movieArrayColumns) + movie2] = 0;
			movieArray[movie2* (*movieArrayColumns) + movie1] = 0;
		}
		else
		{
			float temp = top / (sqrt(bottomLeft) * sqrt(bottomRight));
			movieArray[movie1* (*movieArrayColumns) + movie2] = temp;
			movieArray[movie2* (*movieArrayColumns) + movie1] = temp;
		}
	}
	if (movie1 < 10 && movie2 < 10 && movie1 >= movie2)
	{
		printf("(movie1, movie2, val)->(%d,%d,%f)\n", movie1, movie2, movieArray[movie1* (*movieArrayColumns) + movie2]);
		printf("(movie2, movie1, val)->(%d,%d,%f)\n", movie2, movie1, movieArray[movie2* (*movieArrayColumns) + movie1]);
	}
	if (movie2 == 9124 && movie1 > 9100)
		printf("movie1,movie2:%d,%d\n", movie1, movie2);
}


//void quicksort(float)

__global__ void computeRecommendedMovies(float*userArray, unsigned short *userArrayColumns, unsigned short *userArrayRows, float*movieArray, bool *didSelect)
{
	short movie = blockDim.x * blockIdx.x + threadIdx.x + 1;
	short user = blockDim.y * blockIdx.y + threadIdx.y + 1;
	float tempSim;
	short selected = 0;
	float top5[6];
	short top5Index[6];
	if (movie < *userArrayColumns && user < *userArrayRows && !didSelect[user* (*userArrayColumns) + movie])
	{
		for (int i = 1; i < *userArrayColumns; i++)
		{
			if (i != movie && didSelect[user * (*userArrayColumns) + i])
			{
				tempSim = movieArray[movie * (*userArrayColumns) + i];
				if (selected < 5)
				{
					top5[5-selected] = tempSim;
					top5Index[5-selected] = i;
					selected++;
				}
				else
				{
					top5[0] = tempSim;
					top5Index[0] = i;
					float temp;
					short temp2;

					//bubble sort......
					for (int i2 = 0; i2 <= 5; i2++)
					{
						for (int j = 0; j < 5; j++)
						{
							if (top5[j] > top5[j + 1] || (top5[j] == top5[j + 1] && top5Index[j] > top5Index[j + 1]))
							{
								temp = top5[j];
								temp2 = top5Index[j];

								top5[j] = top5[j + 1];
								top5Index[j] = top5Index[j + 1];

								top5[j + 1] = temp;
								top5Index[j + 1] = temp2;
							}
						}
					}
				}
			}
		}
		double sum = 0;
		for (int i = 1; i <=selected; i++)
			sum+= top5[i] * movieArray[movie * (*userArrayColumns) + top5Index[i]];
		userArray[user * (*userArrayColumns) + movie] = sum / selected;
		if (movie == 8500 && user > 660)
			printf("user,movie:%d,%d\n", user, movie);
	}
}


void outputData(unsigned short * recomendedMoviesMatrix, unsigned short rows, unsigned short columns, MovieReader m)
{
	fstream f;
	f.open("output.csv", std::fstream::out);
	for (int i = 1; i < rows; i++)
	{
		stringstream ss;
		ss << i;
		for (int j = 0; j < columns; j++)
		{
			ss << ',' << m.movieMapper[recomendedMoviesMatrix[i * columns + j]].movieID;
		}
		f << "user_" << ss.str()<< endl;
	}
	f.close();

}


void populateUserReviewMatrix(float *userReviewMatrix, bool *originalReviewMatrix, UserTableReader r, MovieReader m)
{
	auto vec = r.users;
	for (auto it = vec.begin(); it != vec.end(); ++it)
	{
		for (auto sit = (*it).ratedMovies.begin(); sit != (*it).ratedMovies.end(); ++sit)
		{
			userReviewMatrix[(*it).userID * (m.movieCount +1) + m.movieIDMapper[(*sit).movieID]] = (*sit).rating;
			originalReviewMatrix[(*it).userID * (m.movieCount + 1) + m.movieIDMapper[(*sit).movieID]] = true;
		}
	}
}

cudaError_t doAlgo()
{
	printf("----------------------StartedCode-----------------------\n");
	auto t1 = std::chrono::high_resolution_clock::now();
	MovieReader m = MovieReader("movie.csv");
	UserTableReader r = UserTableReader("ratings.csv");

	auto t2 = std::chrono::high_resolution_clock::now();
	printf("-------Filing Reading completed in %d milliseconds------\n\n\n", std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count());
	printf("--------------StartedMatrixBuilding---------------------\n");
	auto t3 = std::chrono::high_resolution_clock::now();


	float * movieMatrix = (float *)calloc((m.movieCount + 1) * (m.movieCount + 1), sizeof(float));

	for (int i = 1; i < (m.movieCount + 1); i++)
	{
		movieMatrix[i*(m.movieCount + 1) + i] = 1;
	}
	float * userReviewMatrix = (float *)calloc((r.users.size()+1) * (m.movieCount + 1), sizeof(float));
	bool * originalReviewMatrix = (bool *)calloc( (r.users.size() + 1) * (m.movieCount + 1), sizeof(bool));
	unsigned short * recomendedMoviesMatrix = (unsigned short*)calloc((r.users.size() + 1) * 5, sizeof(unsigned short));
	populateUserReviewMatrix(userReviewMatrix, originalReviewMatrix, r, m);


	auto t4 = std::chrono::high_resolution_clock::now();
	printf("-------matrix created completed in %d milliseconds------\n\n\n", std::chrono::duration_cast<std::chrono::milliseconds>(t4 - t3).count());
	printf("-----------------Started Cuda data copy-----------------\n");
	auto t5 = std::chrono::high_resolution_clock::now();

	string str2;
	cudaError_t cudaStatus;
	int movieMatrixColumns = m.movieCount + 1;
	int userReviewColumns = m.movieCount + 1;
	int userReviewRows = r.users.size() + 1;
	unsigned short recomendedMoviesMatrixColumns = 5;
	unsigned short recomendedMoviesMatrixRows = (r.users.size() + 1);

	float * d_movieMatrix;
	cudaStatus = cudaMalloc((void**)&d_movieMatrix, sizeof(float) * movieMatrixColumns * movieMatrixColumns);
	cudaStatus = cudaMemcpy(d_movieMatrix, movieMatrix, sizeof(float) * movieMatrixColumns * movieMatrixColumns, cudaMemcpyHostToDevice);

	unsigned short * d_recomendedMoviesMatrix;
	cudaMalloc((void**)&d_recomendedMoviesMatrix, sizeof(unsigned short) * recomendedMoviesMatrixRows * recomendedMoviesMatrixColumns);
	cudaStatus = cudaMemcpy(d_recomendedMoviesMatrix, recomendedMoviesMatrix, sizeof(unsigned short)* recomendedMoviesMatrixRows * recomendedMoviesMatrixColumns, cudaMemcpyHostToDevice);

	unsigned short * d_recMoviesColumns;
	cudaStatus = cudaMalloc((void**)&d_recMoviesColumns, sizeof(unsigned short));
	cudaStatus = cudaMemcpy(d_recMoviesColumns, &recomendedMoviesMatrixColumns, sizeof(unsigned short), cudaMemcpyHostToDevice);

	unsigned short * d_userReviewMatrixColumns;
	cudaStatus = cudaMalloc((void**)&d_userReviewMatrixColumns, sizeof(unsigned short) * 1);
	cudaStatus = cudaMemcpy(d_userReviewMatrixColumns,&userReviewColumns,sizeof(unsigned short), cudaMemcpyHostToDevice);

	unsigned short * d_userReviewMatrixRows;
	cudaStatus = cudaMalloc((void**)&d_userReviewMatrixRows, sizeof(unsigned short) * 1);
	cudaStatus = cudaMemcpy(d_userReviewMatrixRows, &userReviewRows, sizeof(unsigned short), cudaMemcpyHostToDevice);

	float * d_userReviewMatrix;
	cudaStatus = cudaMalloc((void**)&d_userReviewMatrix, sizeof(float) * userReviewRows * userReviewColumns);
	cudaStatus = cudaMemcpy(d_userReviewMatrix, userReviewMatrix, sizeof(float)* userReviewRows * userReviewColumns, cudaMemcpyHostToDevice);

	
	bool * d_didReviewMatrix;
	cudaStatus = cudaMalloc((void**)&d_didReviewMatrix, sizeof(bool) * userReviewRows * userReviewColumns);
	cudaStatus = cudaMemcpy(d_didReviewMatrix, originalReviewMatrix, sizeof(bool) * userReviewRows * userReviewColumns, cudaMemcpyHostToDevice);

	cudaStatus = cudaDeviceSynchronize();

	auto t11 = std::chrono::high_resolution_clock::now();
	auto t12 = std::chrono::high_resolution_clock::now();
	while (std::chrono::duration_cast<std::chrono::milliseconds>(t12 - t11).count() < 20000 )
		t12 = std::chrono::high_resolution_clock::now();


	int blockX = ceil(userReviewRows / 256.0);
	int blockY = ceil(userReviewRows / 16.0);
	int blockXType2 = ceil(userReviewColumns / 256);

	auto t6 = std::chrono::high_resolution_clock::now();
	printf("-------cuda data copy completed in %lld milliseconds------\n\n\n", std::chrono::duration_cast<std::chrono::milliseconds>(t6 - t5).count());
	printf("--------Started Compute Averages for movies-------------\n");
	auto t7 = std::chrono::high_resolution_clock::now();


	centerMatrix<< <blockXType2, 256 >> > (d_userReviewMatrix, d_userReviewMatrixColumns, d_userReviewMatrixRows);
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %s after launching computeAverageType2!\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	auto t8 = std::chrono::high_resolution_clock::now();
	printf("-------Compute Averages for movies completed in %lld milliseconds------\n\n\n", std::chrono::duration_cast<std::chrono::milliseconds>(t8 - t7).count());
	printf("--------Started compute simularMovies-------------\n");
	auto t9 = std::chrono::high_resolution_clock::now();
	float blockDim = 32.0;
	blockX = ceil(movieMatrixColumns / blockDim );
	blockY = ceil(movieMatrixColumns / blockDim);

	computeSimularMoviesType2<<<dim3(blockX, blockY), dim3(blockDim, blockDim) >>>(d_userReviewMatrix, d_userReviewMatrixRows, d_movieMatrix, d_userReviewMatrixColumns);

	cudaStatus = cudaGetLastError();
	if (cudaSuccess != cudaGetLastError())
		printf("Error!\n");
	cudaStatus = cudaGetLastError();
	cudaDeviceSynchronize();
	cudaStatus = cudaGetLastError();
	str2 = cudaGetErrorString(cudaStatus);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %s after launching computeSimularMoviesType2!\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	blockX = ceil(movieMatrixColumns / 16.0);
	blockY = ceil(userReviewRows / 16.0);

	t8 = std::chrono::high_resolution_clock::now();
	printf("Compute simular movies completed in %lld milliseconds\n\n\n", std::chrono::duration_cast<std::chrono::milliseconds>(t8 - t9).count());
	printf("------Started compute recommended movies-----------\n");
	t9 = std::chrono::high_resolution_clock::now();


	computeRecommendedMovies<<<dim3(blockX, blockY), dim3(16, 16) >>>(d_userReviewMatrix, d_userReviewMatrixColumns, d_userReviewMatrixRows, d_movieMatrix, d_didReviewMatrix);
	cudaStatus = cudaGetLastError();
	if (cudaSuccess != cudaGetLastError())
		printf("Error!\n");
	cudaDeviceSynchronize();
	cudaStatus = cudaGetLastError();

	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching computeRecommendedMovies!\n", cudaStatus);
		goto Error;
	}

	t8 = std::chrono::high_resolution_clock::now();
	printf("Compute recommended movies completed in %lld milliseconds\n", std::chrono::duration_cast<std::chrono::milliseconds>(t8 - t9).count());
	blockX = ceil(userReviewRows / 16.0);
	cudaError_t cuda3 = cudaGetLastError();
	str2 = cudaGetErrorString(cuda3);

	loadTop5 << <blockX, 16 >> > (d_userReviewMatrix, d_userReviewMatrixRows, d_userReviewMatrixColumns, d_recomendedMoviesMatrix, d_recMoviesColumns, d_didReviewMatrix);
	cudaError_t cuda2 = cudaGetLastError();
	str2 = cudaGetErrorString(cuda2);
	cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
		goto Error;
	}

	cudaStatus = cudaMemcpy(recomendedMoviesMatrix, d_recomendedMoviesMatrix, sizeof(unsigned short)* recomendedMoviesMatrixRows * recomendedMoviesMatrixColumns, cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "Cuda MemCpy failed!!\n", cudaStatus);
		goto Error;
	}
	outputData(recomendedMoviesMatrix, userReviewRows, 5, m);

Error:
	cudaFree(d_recMoviesColumns);
	cudaFree(d_recomendedMoviesMatrix);
	cudaFree(d_didReviewMatrix);
	cudaFree(d_movieMatrix);
	cudaFree(d_userReviewMatrix);
	cudaFree(d_userReviewMatrixColumns);
	cudaFree(d_userReviewMatrixRows);

		return cudaStatus;
}

int main()
{

	CUDABackground cuda = CUDABackground();
	doAlgo();
}