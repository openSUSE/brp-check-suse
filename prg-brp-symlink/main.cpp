#include <iostream>
#include <string>
#include <filesystem>

using namespace std;

// synopsis: read from stdin lines per link
// IFS=| link link_dest
// (where link is a relative path to buildroot)
// output one line per link:
// IFS=| link link_orig link_dest link_absolut

// NOTE:
// the actual file system content is of no concern here

void check_link(const string &link, const string &link_dest) {
   std::filesystem::path link_path(link);
   std::filesystem::path link_dest_path = link_path.parent_path().append(link_dest);
   std::filesystem::path link_dest_abs(link_dest_path.lexically_normal().string());
   cout << link << "|"
        << link_dest << "|"
        << link_dest_abs.lexically_relative(link_path.parent_path()).string() << "|"
        << link_dest_abs.string() << endl;
}

void work_line(const string &line) {
    size_t delim = line.find('|');
    check_link("/" + line.substr(0, delim), line.substr(delim+1));
}

int main(int argc, char **argv) {
    for (string line; std::getline(cin, line);) {
      work_line(line);
    }

  return 0;
}
