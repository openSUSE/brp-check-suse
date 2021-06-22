CXXFLAGS ?= -O2 -Wall -g3
CXX ?= g++

all: brp-symlink

brp-symlink: main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^

check: brp-symlink
	./brp-symlink -b testdir < tests.in > tests.new
	diff -u tests.out tests.new

format:
	clang-format --style=WebKit -i main.cpp
