#pragma once
#include <string>
#include <map>
#include <vector>
#include <fstream>
#include "User.h"
#include "Movie.h"
using namespace std;

class UserTableReader
{
public:
	UserTableReader(string fileName);
	~UserTableReader();
	vector<User> users;
};

