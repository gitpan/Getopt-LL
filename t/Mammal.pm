package Mammal;
use strict;
use warnings;
use Class::Dot qw( -new property isa_Data isa_Hash );

property brain  => isa_Hash;
property dna    => isa_Data;

1;
