CXXFLAGS ?= -O2 -Wall
CXX ?= g++

all: brp-symlink

brp-symlink: main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^

check: brp-symlink
	./brp-symlink < tests.in > tests.new
	diff -u tests.out tests.new

