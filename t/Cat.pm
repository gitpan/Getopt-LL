# $Id: Cat.pm,v 1.3 2007/06/27 12:20:49 ask Exp $
# $Source: /opt/CVS/Getopt-LL/t/Cat.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.3 $
# $Date: 2007/06/27 12:20:49 $
package Cat;
use strict;
use warnings;
use FindBin qw($Bin);
use lib 'lib';
use lib $Bin;
use lib 't';
use lib "$Bin/../lib";
use Class::Dot qw( -new :std );
use base 'Mammal';
{

    # A cat's properties, with their default values and type of data.
    property gender      => isa_String('male');
    property memory      => isa_Hash;
    property state       => isa_Hash(instinct => 'hungry');
    property family      => isa_Array;
    #property dna         => isa_Data;
    property action      => isa_Data;
    property colour      => isa_Int(0xfeedface);
    property fur         => isa_Array('short');

    sub test_new {
        my ($self) = @_;
        return $self->{__test_new};
    }

    sub set_test_new {
        my ($self, $value) = @_;
        $self->{__test_new} = $value;
        return;
    }

    sub BUILD {
        my ($self, $options_ref) = @_;
        $self->set_test_new('BUILD and -new works!');
        return;
    }

    sub DEMOLISH {
       return; 
    }
}

1;
__END__
 
     package main;
 
     my $albert = new Animal::Mammal::Carnivorous::Cat('male');
     $albert->memory->{name} = 'Albert';
     $albert->state->{appetite} = 'insane';
     $albert->set_fur([qw(short thin shiny)]);
     $albert->set_action('hunting');
 
     my $lucy = new Animal::Mammal::Carnivorous::Cat('female');
     $lucy->memory->{name} = 'Lucy';
     $lucy->state->{instinct => 'tired'};
     $lucy->set_fur([qw(fluffy long)]);
     $lucy->set_action('sleeping');
 
     push @{ $lucy->family   }, [$albert];
     push @{ $albert->family }, [$lucy  ];


1;

