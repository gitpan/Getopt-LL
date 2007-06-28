package TestProperties;
use strict;
use warnings;
use Class::Dot qw( -new :std );

property foo => isa_Data;
property bar => isa_Data;
property defval => isa_String('la liberation');
property array  => isa_Array(qw(the quick brown fox ...));
property hash   => isa_Hash(hello => 'world', goobye => 'wonderful');
property digit  => isa_Int(303);
property intnoval => isa_Int;
property obj    => isa_Object('TestProperties');
property nofunc => 'This does not use isa_*';
property 'nodefault';
property string => isa_String();

1;

