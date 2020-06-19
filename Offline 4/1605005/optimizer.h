#include <bits/stdc++.h>

using namespace std;

string l_trim(string str)
{
    //trims leading tab or spaces
    string ret;

    bool flag = false;

    for(int i=0; i<str.size(); i++)
    {
        if(!(!flag && (str[i] == ' ' || str[i] == '\t')))
        {
            flag = true;
            ret.push_back(str[i]);
        }
    }
    return ret;
}

string c_trim(string str)
{
    //trims comma
    string ret;

    for(int i=0; i<str.size(); i++)
    {
        if(str[i] != ',')
            ret.push_back(str[i]);
    }

    return ret;
}

string optimize(string str)
{
    string ret;
    vector<string> lines;
    vector<string> lines2;
    vector<string> line1;
    vector<string> line2;
    stringstream code(str);
    string temp;

    bool flag = false;

    while(getline(code, temp, '\n'))
    {
        lines.push_back(l_trim(temp));
        lines2.push_back(temp);
    }

    for(int i = 0; i<lines.size(); i++)
    {
        if(i != lines.size() - 1) //if last line, nothing to check
        {
            flag = false;

            stringstream c1(lines[i]);
            line1.clear();

            while(getline(c1, temp, ' '))
            {
                line1.push_back(temp);
            }

            stringstream c2(lines[i+1]);
            line2.clear();

            while(getline(c2, temp, ' '))
            {
                line2.push_back(temp);
            }

            if(line1[0] == "mov" && line2[0] == "mov")
            {
                if((c_trim(line1[1]) == line2[2]) && (line1[2] == c_trim(line2[1])))
                    flag = true;
            }

            ret += lines2[i] + "\n";

            if(flag) //skip the next line
            {
		i++;
		cout<<"skipped line "<<(i+46)<<endl;
            }
        }
        else ret += lines2[i] + "\n"; //last line gets added
    }

    return ret;
}


