#include "fileReader2.h"



Movie MovieReader::getRealMovieName(int id)
{
	return movieMapper[id];
}

MovieReader::MovieReader(string fileName)
{
	fstream f;
	f.open("movies.csv");
	string temp;
	getline(f, temp);
	vector<tuple<string, string, string>> vec;
	while (getline(f,temp))
	{
		int j = 0;
		string tempstr[3];

		for (int i = 0; i < 3; i++)
		{
			while (temp[j] != ',' && temp[j] != 0)
			{
				tempstr[i] += temp[j++];
			}
			j++;
		}
		vec.emplace_back(tempstr[0], tempstr[1], tempstr[2]);
	}
	int count = 0;
	for (auto it = vec.begin(); it != vec.end(); ++it)
	{
		movieMapper[count++] = Movie(*it);
		movieIDMapper[Movie(*it).movieID] = count;
	}
	this->movieCount = count - 1;

}


MovieReader::~MovieReader()
{
}
