#pragma once
#include <string>
#include <iostream>
#include <map>
#include <fstream>
#include <list>
#include <tuple>
using namespace std;
class Movie
{
public:
	int movieID;
	string title;
	list<string> genres;
	Movie();
	Movie(int movieID, string title);
	Movie(tuple<string, string, string> movieStuff);
	Movie(int movieID, string title, string genres);
	void loadGenres(string unparsed);
	~Movie();
};

