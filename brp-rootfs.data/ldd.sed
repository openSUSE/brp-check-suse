# for binary
/^[^[:blank:]]/{
	# push binary to hold space
	x
	# print old contents of hold space if it is not empty (remove newlines)
	s/\n/ /gp
	# and delete it
	d
}

# for dependency
/^[[:blank:]]/{
	# ignore linux-vdso.so.1
	/linux-vdso.so.1/d
	# remove address
	s/[[:blank:]]\+(0x[0-9a-f]\+)[[:blank:]]*$//
	# remove library name without path
	s@^[[:blank:]]\+[^[:blank:]]\+ => @@
	# append to hold space
	H
	# and delete contents (not d because of last line)
	s/^.*$//
}

# when processing last line I need to flush
${
	H
	x
	s/\n/ /gp
}
#:end
