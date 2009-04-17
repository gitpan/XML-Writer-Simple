package XML::Writer::Simple;

use warnings;
use strict;
use Exporter ();
use vars qw/@ISA @EXPORT/;
use XML::DT;
use XML::DTDParser qw/ParseDTDFile/;

=head1 NAME

XML::Writer::Simple - Create XML files easily!

=cut

our $VERSION = '0.05';
@ISA = qw/Exporter/;
@EXPORT = (qw/powertag xml_header/);
our %PTAGS = ();
our $MODULENAME = "XML::Writer::Simple";

=head1 SYNOPSIS

    use XML::Writer::Simple dtd => "file.dtd";

		print xml_header(encoding => 'iso-8859-1');
    print para("foo",b("bar"),"zbr");

=head1 USAGE

This module takes some ideas from CGI to make easier the life for
those who need to generated XML code. You can use the module in three
flavours (or combine them):

=over 4

=item tags

When importing the module you can specify the tags you will be using:

  use XML::Writer::Simple tags => [qw/p b i tt/];

  print p("Hey, ",b("you"),"! ", i("Yes ", b("you")));

that will generate

 <p>Hey <b>you</b>! <i>Yes <b>you</b></i></p>

=item dtd

You can supply a DTD, that will be analyzed, and the tags used:

  use XML::Writer::Simple dtd => "tmx.dtd";

  print tu(seg("foo"),seg("bar"));

=item xml

You can supply an XML (or a reference to a list of XML files). They
will be parsed, and the tags used:

  use XML::Writer::Simple xml => "foo.xml";

  print foo("bar");

=item partial

You can supply an 'partial' key, to generate prototypes for partial tags
construction. For instance:

  use XML::Writer::Simple tags => qw/foo bar/, partial => 1;

  print start_foo;
  print ...
  print end_foo;

=back

=head1 EXPORT

This module export one function for each element at the dtd or xml
file you are using. See below for details.

=head1 FUNCTIONS

=head2 import

Used when you 'use' the module, should not be used directly.

=head2 xml_header

This function returns the xml header string, without encoding
definition, with a trailing new line. Default XML encoding should
be UTF-8, by the way.

You can force an encoding passing it as argument:

  print xml_header(encoding=>'iso-8859-1');

=head2 powertag

Used to specify a powertag. For instance:

  powertag("ul","li");

  ul_li([qw/foo bar zbr ugh/]);

will generate

  <ul>
   <li>foo</li>
   <li>bar</li>
   <li>zbr</li>
   <li>ugh</li>
  </ul>

You can also supply this information when loading the module, with

  use XML::Writer::Simple powertags=>["ul_li","ol_li"];

Powertags support three level tags as well:

  use XML::Writer::Simple powertags=>["table_tr_td"];

  print table_tr_td(['a','b','c'],['d','e','f']);

=cut

sub xml_header {
	my %ops = @_;
	my $encoding = "";
	$encoding =" encoding=\"$ops{encoding}\"" if exists $ops{encoding};
	return "<?xml version=\"1.0\"$encoding?>\n";
}

sub powertag {
  my $nfunc = join("_", @_);
  $PTAGS{$nfunc}=[@_];
  push @EXPORT, $nfunc;
  XML::Writer::Simple->export_to_level(1, $MODULENAME, $nfunc);
}

sub _xml_from {
  my ($tag, $attrs, @body) = @_;
  return (ref($body[0]) eq "ARRAY")?
    join("", map{ _toxml($tag, $attrs, $_) } @{$body[0]})
      :_toxml($tag, $attrs, join("", @body));
}

sub _clean_attrs {
  my $attrs = shift;
  for (keys %$attrs) {
    if (m!^-!) {
      $attrs->{$'}=$attrs->{$_};
      delete($attrs->{$_});
    }
  }
  return $attrs;
}

sub _toxml {
	my ($tag,$attr,$contents) = @_;
	if (defined($contents) && $contents ne "") {
		return _start_tag($tag,$attr) . $contents . _close_tag($tag);		
	}
	else {
		return _empty_tag($tag,$attr);
	}
}

sub _go_down {
  my ($tags, @values) = @_;
  my $tag = shift @$tags;

  if (@$tags) {
    join("",
         map {
           my $attrs = {};
           if (ref($_->[0]) eq 'HASH') {
             $attrs = _clean_attrs(shift @$_);
           }
           _xml_from($tag,$attrs,_go_down([@$tags],@$_)) } ### REALLY NEED TO COPY
         @values)
  } else {
    join("",
         map { _xml_from($tag,{},$_) } @values)
  }
}

sub AUTOLOAD {
  my $attrs = {};
  my $tag = our $AUTOLOAD;

  $tag =~ s!${MODULENAME}::!!;

  $attrs = shift if ref($_[0]) eq "HASH";
  $attrs = _clean_attrs($attrs);

  if (exists($PTAGS{$tag})) {
    my @tags = @{$PTAGS{$tag}};
    my $toptag = shift @tags;
    return _xml_from($toptag, $attrs,
                     _go_down(\@tags, @_));
  }
	else {
		if ($tag =~ m/^end_(.*)$/) {
			return _close_tag($1)."\n";
		}
		elsif ($tag =~ m/^start_(.*)$/) {
			return _start_tag($1, $attrs)."\n";
		}
		else {	
	    return _xml_from($tag,$attrs,@_);
		}
  }
}

sub _start_tag {
	my ($tag,$attr) = @_;
	$attr = join(" ",map { "$_=\"$attr->{$_}\""} keys %$attr);
	if ($attr) {
		return "<$tag $attr>"
	} else {
		return "<$tag>"
	}
}

sub _empty_tag {
	my ($tag,$attr) = @_;
	$attr = join(" ",map { "$_=\"$attr->{$_}\""} keys %$attr);
	if ($attr) {
		return "<$tag $attr/>"
	} else {
		return "<$tag/>"
	}
}

sub _close_tag {
	my $tag = shift;
	return "</$tag>";
}

sub import {
  my $class = shift;
  my %opts  = @_;

	my $partial = 0;
	$partial = 1 if exists $opts{partial};

  if (exists($opts{tags})) {
    if (ref($opts{tags}) eq "ARRAY") {
      push @EXPORT, @{$opts{tags}};
			if ($partial) {
				push @EXPORT, map { "start_$_" } @{$opts{tags}};
				push @EXPORT, map { "end_$_"   } @{$opts{tags}};
			}
    }
  }

  if (exists($opts{xml})) {
    my @xmls = (ref($opts{xml}) eq "ARRAY")?@{$opts{xml}}:($opts{xml});
    my $tags;
    for my $xml (@xmls) {
      dt($xml, -default => sub { $tags->{$q}++ });
    }
    push @EXPORT, keys %$tags;
		if ($partial) {
			push @EXPORT, map { "start_$_" } keys %$tags;
			push @EXPORT, map { "end_$_"   } keys %$tags;
		}
  }

  if (exists($opts{dtd})) {
    my $DTD = ParseDTDFile($opts{dtd});
    push @EXPORT, keys %$DTD;
		if ($partial) {
			push @EXPORT, map { "start_$_" } keys %$DTD;
			push @EXPORT, map { "end_$_"   } keys %$DTD;
		}
  }

  if (exists($opts{powertags})) {
    my @ptags = @{$opts{powertags}};
    @PTAGS{@ptags} = map { [split/_/] } @ptags;
    push @EXPORT, @ptags;
  }

  XML::Writer::Simple->export_to_level(1, $class, @EXPORT);
}

=head1 AUTHOR

Alberto Simoes, C<< <ambs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-writer-simple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Writer-Simple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Alberto Simoes, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of XML::Writer::Simple
