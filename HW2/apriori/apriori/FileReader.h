#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string>
using namespace std;

class FileReader
{
public:
	int**master;
	int count;
	int maxNumber;
	FileReader(string fileName);

	~FileReader();
};

