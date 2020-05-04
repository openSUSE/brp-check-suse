all: brp-symlink

brp-symlink: main.cpp
	g++ -std=c++17 main.cpp -o brp-symlink

check: brp-symlink
	./brp-symlink < tests.in > tests.new
	diff -u tests.out tests.new

