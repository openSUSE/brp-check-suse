#include <iostream>
#include <iterator>
#include <limits.h>
#include <sstream>
#include <string>
#include <unistd.h>
#include <vector>

// synopsis: read from stdin lines per link
// IFS=| link link_dest
// (where link is a relative path to buildroot)
// output one line per link:
// IFS=| link link_orig link_dest link_absolut

// NOTE:
// it's important to run this with the root as cwd
// so the link expansion is done correctly

using namespace std;

string buildroot = ".";

string append(const string& p1, const string& p2)
{
    char sep = '/';
    if (p2[0] == sep)
        return p2;

    string tmp = p1;

    size_t len = p1.length();
    while (len && p1[len] != sep)
        len--;
    tmp.resize(len + 1);

    return (tmp + p2);
}

vector<string> split_paths(const string& path)
{
    string token;
    vector<string> paths;
    stringstream ss(path);
    while (getline(ss, token, '/')) {
        if (token == "..") {
            paths.pop_back();
        } else if (token != "." || ss.eof()) {
            paths.push_back(token);
        }
    }
    return paths;
}

string merge_paths(vector<string> paths)
{
    string path;
    for (const auto& s : paths) {
        if (s.empty())
            continue;
        if (!path.empty())
            path += "/";
        path += s;
    }

    return path;
}

string normalize(string path)
{
    vector<string> paths = split_paths(path);
    return "/" + merge_paths(paths);
}

string relative(const string& p1, const string& p2)
{
    vector<string> paths1 = split_paths(p1);
    paths1.pop_back();
    vector<string> paths2 = split_paths(p2);
    vector<string> paths;
    vector<string>::const_iterator it1 = paths1.begin();
    vector<string>::const_iterator it2 = paths2.begin();
    // first remove the common parts
    while (it1 != paths1.end() && *it1 == *it2) {
        it1++;
        it2++;
    }
    for (; it1 != paths1.end(); ++it1) {
        paths.push_back("..");
    }
    for (; it2 != paths2.end(); ++it2) {
        paths.push_back(*it2);
    }

    return merge_paths(paths);
}

string check_exceptions(const string& link_relative, const string& link_absolute)
{
    // update alternative links are special
    if (!link_absolute.rfind("/etc/alternatives/", 0)) {
        return link_absolute;
    }
    // links pointing into kernel file system should be absolute
    if (!link_absolute.rfind("/proc/", 0) || !link_absolute.rfind("/dev/", 0) || !link_absolute.rfind("/sys/", 0)) {
        return link_absolute;
    }
    return link_relative;
}

// expand the file against root and buildroot
string follow(const string& path)
{
    vector<string> paths = split_paths(path);
    vector<string>::const_iterator it = paths.begin();
    string new_path = "";
    for (; it != paths.end(); it++) {
        if (!it->length())
            continue;
        string tmp_path = new_path + "/" + *it;

        char buffer[PATH_MAX];
        string tmp_path_in_buildroot = buildroot + "/" + tmp_path;
        ssize_t result = readlink(tmp_path_in_buildroot.c_str(), buffer, PATH_MAX);
        if (result > 0) {
            buffer[result] = 0;
            // for absolute links within buildroot we need to recurse
            if (buffer[0] == '/') {
                new_path.assign(buffer);
                for (it++; it != paths.end(); it++) {
                    new_path += "/" + *it;
                }
                return follow(new_path);
            }
        }
        new_path = tmp_path;
    }
    return path;
}

void check_link(const string& link, const string& link_old_dest)
{
    string link_dest_path = append(link, link_old_dest);
    string link_dest_abs = normalize(link_dest_path);
    string link_new_dest = relative(normalize(link), link_dest_abs);
    cout << link << "|"
         << link_old_dest << "|"
         << check_exceptions(link_new_dest, link_dest_abs) << "|"
         << follow(link_dest_abs) << endl;
}

void work_line(const string& line)
{
    size_t delim = line.find('|');
    check_link("/" + line.substr(0, delim), line.substr(delim + 1));
}

int main(int argc, char** argv)
{
    while (true) {
        switch (getopt(argc, argv, "r:b:")) {
        case '?':
        case 'h':
        default:
            cerr << argv[0] << " [-b <buildroot>]\n";
            cerr << "  buildroot defaults to .\n";
            return -1;

        case -1:
            break;

        case 'b':
            buildroot.assign(optarg);
            continue;
        }
        break;
    }

    for (string line; getline(cin, line);) {
        work_line(line);
    }

    return 0;
}
