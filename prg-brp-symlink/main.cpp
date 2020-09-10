#include <iostream>
#include <string>

#if defined(__cplusplus) && __cplusplus >= 201703L && defined(__has_include) && __has_include(<filesystem>)
#include <filesystem>
namespace fs = std::filesystem;
#else
#include <ghc/filesystem.hpp>
namespace fs = ghc::filesystem;
#endif

// synopsis: read from stdin lines per link
// IFS=| link link_dest
// (where link is a relative path to buildroot)
// output one line per link:
// IFS=| link link_orig link_dest link_absolut

// NOTE:
// the actual file system content is of no concern here

void check_link(const std::string &link, const std::string &link_dest) {
   fs::path link_path(link);
   fs::path link_dest_path = link_path.parent_path().append(link_dest);
   fs::path link_dest_abs(link_dest_path.lexically_normal().string());
   std::cout << link << "|"
        << link_dest << "|"
        << link_dest_abs.lexically_relative(link_path.parent_path()).string() << "|"
        << link_dest_abs.string() << std::endl;
}

void work_line(const std::string &line) {
    size_t delim = line.find('|');
    check_link("/" + line.substr(0, delim), line.substr(delim+1));
}

int main(int argc, char **argv) {
    for (std::string line; std::getline(std::cin, line);) {
      work_line(line);
    }

  return 0;
}
