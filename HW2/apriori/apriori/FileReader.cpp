#include "FileReader.h"
#include <string>
#include <iostream>
#include <fstream>
using namespace std;


FileReader::FileReader(string fileName)
{
	fstream myFile;
	myFile.open(fileName);
	long count = 0;
	while (!myFile.eof())
	{
		char junk[500];
		myFile.getline(junk, 50000);
		count++;
	}
	myFile.close();
	myFile.open(fileName);
	int curIndex = 0;
	master = (int **)malloc(sizeof(int *) * (count + 1));
	this->count = count;
	while (!myFile.eof())
	{
		char temp[1024];
		myFile.getline(temp, 1024);
		int spacecount = 0;
		for (int i = 0; temp[i] != '\0'; i++)
		{
			if (temp[i] == ' ')
				spacecount++;
		}
		int * arr = (int*)malloc(sizeof(int) * (spacecount + 1));
		char * pch;
		pch = strtok(temp, " ");
		master[curIndex] = arr;
		arr[0] = spacecount;
		int i = 1;
		while (pch != NULL)
		{
			arr[i++] = stoi(pch);
			if (stoi(pch) > maxNumber)
				maxNumber = stoi(pch);
			pch = strtok(NULL, " ");
		}
		curIndex++;
	}
}


FileReader::~FileReader()
{
}
