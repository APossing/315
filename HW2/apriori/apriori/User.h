#pragma once
#include <string>
#include <vector>
#include <list>
#include "MovieRating.h"
using namespace std;
class User
{

public:
	vector<MovieRating> ratedMovies;
	int userID;
	User(string id);
	void insertRatedMovie(string mappedMovieID, string rating);
	~User();
private:

};

