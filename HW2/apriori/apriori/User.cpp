#include "User.h"



User::User(string id)
{
	this->userID = atoi(id.c_str());
}


void User::insertRatedMovie(string mappedMovieID, string rating)
{
	ratedMovies.emplace_back(atoi(mappedMovieID.c_str()), atof(rating.c_str()));
}

User::~User()
{
}
