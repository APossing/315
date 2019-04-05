#include "Movie.h"



Movie::Movie()
{
}

Movie::Movie(int movieID, string title)
{
	genres = list<string>();
	this->movieID = movieID;
	this->title = title;
}

Movie::Movie(tuple<string,string,string> movieStuff)
{
	this->movieID = atoi(get<0>(movieStuff).c_str());
	this->title = get<1>(movieStuff);
	loadGenres(get<2>(movieStuff));

}

Movie::Movie(int movieID, string title, string genres)
{
	this->genres = list<string>();
	this->movieID = movieID;
	this->title = title;
	loadGenres(genres);
}

void Movie::loadGenres(string unparsed)
{
	// TODO Finish this....
	genres.push_front(unparsed);
	//boost::split(genres, unparsed, boost::is_any_of("|"));
}


Movie::~Movie()
{
}
