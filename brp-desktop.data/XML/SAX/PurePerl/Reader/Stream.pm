# $Id: Stream.pm,v 1.7 2005-10-14 20:31:20 matt Exp $

package XML::SAX::PurePerl::Reader::Stream;

use strict;
use vars qw(@ISA);

use XML::SAX::PurePerl::Reader qw(
    EOF
    BUFFER
    LINE
    COLUMN
    ENCODING
    XML_VERSION
);
use XML::SAX::Exception;

@ISA = ('XML::SAX::PurePerl::Reader');

# subclassed by adding 1 to last element
use constant FH => 8;
use constant BUFFER_SIZE => 4096;

sub new {
    my $class = shift;
    my $ioref = shift;
    XML::SAX::PurePerl::Reader::set_raw_stream($ioref);
    my @parts;
    @parts[FH, LINE, COLUMN, BUFFER, EOF, XML_VERSION] =
        ($ioref, 1,   0,      '',     0,   '1.0');
    return bless \@parts, $class;
}

sub read_more {
    my $self = shift;
    my $buf;
    my $bytesread = read($self->[FH], $buf, BUFFER_SIZE);
    if ($bytesread) {
        $self->[BUFFER] .= $buf;
        return 1;
    }
    elsif (defined($bytesread)) {
        $self->[EOF]++;
        return 0;
    }
    else {
        throw XML::SAX::Exception::Parse(
            Message => "Error reading from filehandle: $!",
        );
    }
}

sub move_along {
    my $self = shift;
    my $discarded = substr($self->[BUFFER], 0, $_[0], '');
    
    # Wish I could skip this lot - tells us where we are in the file
    my $lines = $discarded =~ tr/\n//;
    $self->[LINE] += $lines;
    if ($lines) {
        $discarded =~ /\n([^\n]*)$/;
        $self->[COLUMN] = length($1);
    }
    else {
        $self->[COLUMN] += $_[0];
    }
}

sub set_encoding {
    my $self = shift;
    my ($encoding) = @_;
    # warn("set encoding to: $encoding\n");

    # make sure that the buffer used to detect the encoding 
    # does not end in the middle of a utf8 sequence
    if ($encoding eq 'UTF-8' && 
         !$self->[EOF] && 
         !utf8::is_utf8($self->[BUFFER]) && # make sure we do not do it twice
         length($self->[BUFFER]) > 5) {

	my $x = reverse(substr($self->[BUFFER], -5));
	my $y = 0;
	
	# skip the all the bytes at the end of buffer
	# starting with bits 10 (continuation bytes of utf8 sequence)
	while ($x ne "" && (ord($x) & 0xc0) == 0x80) {
	    $y--;
	    $x = substr($x, 1);
	}

        # if $x is ascii character, do nothing
	# otherwise we must take a look how many
	# continuation bytes we need
	if ((ord($x) & 0xc0) == 0xc0) {
	  $x = ord($x);
	  if (($x & 0xe0) == 0xc0) { # the sequence contains one more byte
	    $y++;
	  } elsif (($x & 0xf0) == 0xe0) { # ...2 bytes
	    $y += 2;
	  } elsif (($x & 0xf8) == 0xf0) { # ...3 bytes
	    $y += 3;
	  } elsif (($x & 0xfc) == 0xf8) { # ...4 bytes
	    $y += 4;
	  } elsif (($x & 0xfe) == 0xfc) { # ...5 bytes
	    $y += 5;
	  }

          # read the last sequence in the buffer completely, if needed
	  if ($y > 0) {
	    my $buf;
	    my $bytesread = read($self->[FH], $buf, $y);
	    if ($bytesread) {
		$self->[BUFFER] .= $buf;
	    } elsif (defined($bytesread)) {
		$self->[EOF]++;
	    }
	  }
	}
      }

    XML::SAX::PurePerl::Reader::switch_encoding_stream($self->[FH], $encoding);
    XML::SAX::PurePerl::Reader::switch_encoding_string($self->[BUFFER], $encoding);
    $self->[ENCODING] = $encoding;
}

sub bytepos {
    my $self = shift;
    tell($self->[FH]);
}

1;

