
package XML::Parser::MySAXHandler;

use base qw(XML::SAX::Base);

sub start_document {
  my ($self, $doc) = @_;
  $self->{Lists} = [];
  $self->{Curlist} = $self->{Tree} = [];
}
sub start_element {
  my ($self, $el) = @_;
  my $attrs = {};
  $attrs->{$_->{'Name'}} = $_->{'Value'} for values %{$el->{Attributes}};
  my $newlist = [ $attrs ];
  push @{ $self->{Lists} }, $self->{Curlist};
  push @{ $self->{Curlist} }, $el->{Name} => $newlist;
  $self->{Curlist} = $newlist;
}
sub end_element {
  my ($self, $el) = @_;
  $self->{Curlist} = pop @{ $self->{Lists} };
}
sub characters {
  my ($self, $el) = @_;
  my $clist = $self->{Curlist};
  my $pos = $#$clist;
  my $text = $el->{Data};
  
  if ($pos > 0 and $clist->[$pos - 1] eq '0') {
    $clist->[$pos] .= $text;
  } else {
    push @$clist, 0 => $text;
  }
}
sub final {
  my ($self) = @_;
  delete $self->{Curlist};
  delete $self->{Lists};
  $self->{Tree};
}

package XML::Parser;

use Carp;
use XML::SAX;
use XML::SAX::PurePerl;


sub new {
  die unless @_ == 3 && $_[1] eq 'Style' && $_[2] eq 'Tree';
  return bless {};
}
sub parse {
  my ($self, $xml) = @_;
  my $handler = XML::Parser::MySAXHandler->new;
  my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
  $parser->parse_string($xml);
  return $handler->final();
}
sub parsefile {
  my $self = shift;
  my $file = shift;
  local(*FILE);
  open(FILE, $file) or  croak "Couldn't open $file:\n$!";
  binmode(FILE);
  my $handler = XML::Parser::MySAXHandler->new;
  my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
  eval {
    $parser->parse_file(*FILE);
  };
  my $err = $@;
  close(FILE);
  die $err if $err;
  return $handler->final();
}

1;
