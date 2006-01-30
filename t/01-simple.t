#!/usr/bin/perl 

use Test::More tests => 8;
use XML::Writer::Simple tags => [qw/a b c d e/];

is(a(b(c(d(e('f'))))), "<a><b><c><d><e>f</e></d></c></b></a>");

is(a(b('a'),c('a')), "<a><b>a</b><c>a</c></a>");

is(a(b(['a'..'h'])), "<a><b>a</b><b>b</b><b>c</b><b>d</b><b>e</b><b>f</b><b>g</b><b>h</b></a>");

is(a({-foo=>'bar'}), "<a foo=\"bar\"/>");

is(a({foo=>'bar'}), "<a foo=\"bar\"/>");

is(a({-foo=>'bar'},'x'), "<a foo=\"bar\">x</a>");

is(a({foo=>'bar'},'x'), "<a foo=\"bar\">x</a>");

is(a(), "<a/>");


