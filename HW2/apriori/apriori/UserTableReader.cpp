#include "UserTableReader.h"

UserTableReader::UserTableReader(string fileName)
{
	fstream f;
	f.open(fileName);
	string temp;
	getline(f, temp);
	vector<tuple<string, string, string>> vec;
	while (getline(f, temp))
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

	string previousUserID = "";
	for (auto it = vec.begin(); it != vec.end();++it)
	{
		if (previousUserID != get<0>(*it))
		{
			users.emplace_back(User(get<0>(*it)));
			previousUserID = get<0>(*it);
		}
		users.back().insertRatedMovie(get<1>(*it), get<2>(*it));
	}
}

UserTableReader::~UserTableReader()
{
}
