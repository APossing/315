#include <string>
#include <iostream>
#include <map>
#include <fstream>
#include <vector>
#include "Movie.h"
using namespace std;
#pragma once
class MovieReader
{
public:
	int movieCount;
	Movie getRealMovieName(int id);
	MovieReader(string filename);
	~MovieReader();
	map<int, Movie> movieMapper;
	map<int, int> movieIDMapper;
private:
};