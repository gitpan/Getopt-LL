# $Id: Dot.pm,v 1.2 2007/06/28 18:44:50 ask Exp $
# $Source: /opt/CVS/Getopt-LL/lib/Class/Dot.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.2 $
# $Date: 2007/06/28 18:44:50 $
package Class::Dot;
use strict;
use warnings;
use version; our $VERSION = qv('0.0.4');
use Carp;

my @EXPORT_OK = qw(
    property
    isa_String isa_Int isa_Array isa_Hash isa_Data isa_Object
);

my %EXPORT_CLASS = (':std'  => [@EXPORT_OK],);

#use vars qw( %PROPERTIES_FOR %OPTIONS_FOR );
my %OPTIONS_FOR;
my %PROPERTIES_FOR;

sub import {
    my $this_class   = shift;
    my $caller_class = caller;

    my %options;
    my $export_class;
    my @subs;
    for my $arg (@_) {
        if ($arg =~ m/^-/xms) {
            $options{$arg} = 1;
        }
        elsif ($arg =~ m/^:/xms) {
            croak(   'Only one export class can be used. '
                    ."(Used already: [$export_class] now: [$arg])")
                if $export_class;

            $export_class = $arg;
        }
        else {
            push @subs, $arg;
        }
    }

    my @subs_to_export=
           $export_class
        && $EXPORT_CLASS{$export_class}
        ? (@{ $EXPORT_CLASS{$export_class} }, @subs)
        : @subs;

    no strict 'refs'; ## no critic;
    for my $sub_to_export (@subs_to_export) {
        _install_sub_from_class($this_class, $sub_to_export => $caller_class);
    }

    if ($options{'-new'}) {
        my $constructor = _create_constructor($caller_class);
        _install_sub_from_coderef($constructor => $caller_class, 'new');
    }

    my $destructor = _create_destroy_method($caller_class);
    _install_sub_from_coderef($destructor => $caller_class, 'DESTROY');

    $OPTIONS_FOR{$caller_class}    = \%options;
    $PROPERTIES_FOR{$caller_class} = {};

    return;
}

sub _install_sub_from_class {
    my ($pkg_from, $sub_name, $pkg_to) = @_;
    my $from = join q{::}, ($pkg_from, $sub_name);
    my $to   = join q{::}, ($pkg_to,   $sub_name);

    no strict 'refs'; ## no critic
    *{$to} = *{$from};

    return;
}

sub _install_sub_from_coderef {
    my ($coderef, $pkg_to, $sub_name) = @_;
    my $to = join q{::}, ($pkg_to,   $sub_name);

    no strict 'refs'; ## no critic
    *{$to} = $coderef;

    return;
}

sub _create_constructor {
    my ($CALLPKG) = @_;

    return sub {
        my ($class, $options_ref) = @_;
        $options_ref ||= {};

        local *__ANON__ = $class . 'new'; ## no critic;

        my $self = {};
        bless $self, $class;

        our @ISA;        ## no critic
        my  @isa = @ISA; ## no critic

    OPTION:
        while (my ($opt_key, $opt_value) = each %{$options_ref}) {
            my $has_property = 0;

        ISA:
            for my $isa ($class, @isa) {
                if ($PROPERTIES_FOR{$isa} && $PROPERTIES_FOR{$isa}{$opt_key})
                {
                    $has_property = 1;
                    last ISA;
                }
            }

            if ($has_property) {
                my $set_method = 'set_' . $opt_key;
                $self->$set_method($opt_value);
            }
        }

        no strict 'refs'; ## no critic
        if (my $build_ref = *{ $class . '::BUILD' }{CODE}) {
            $build_ref->($self, $options_ref);
        }

        return $self;
        }
}

sub properties_for_class {
    my ($self, $class) = @_;
    $class = ref $class || $class;

    my %class_properties;

    my @isa_for_class;
    {
        no strict 'refs'; ## no critic
        @isa_for_class = @{ $class . '::ISA' };
    }

    for my $parent ($class, @isa_for_class) {
        for my $parent_property (keys %{ $PROPERTIES_FOR{$parent} }) {
            $class_properties{$parent_property} = 1;
        }
    }

    return \%class_properties;
}

sub _create_destroy_method {
    my ($CALLPKG) = @_;

    return sub {
        my ($self) = @_;
        my $properties_ref =$PROPERTIES_FOR{$CALLPKG};
        undef %{$properties_ref};
        delete$PROPERTIES_FOR{$CALLPKG};

        no strict   'refs'; ## no critic
        no warnings 'once'; ## no critic
        if (my $demolish_ref = *{$CALLPKG.'::DEMOLISH'}{CODE}) {
            $demolish_ref->($self);
        }

        return;
    }
}

sub property (@) { ## no critic
    my ($property, $isa) = @_;
    return if not $property;

    my $caller = caller;

    no strict   'refs';     ## no critic
    no warnings 'redefine'; ## no critic

    my $set_property = 'set_' . $property;

    # Callpkg::property()
    *{ $caller . q{::} . $property }= _create_get_accessor($property, $isa);

    # Callpkg::set_property()
    *{ $caller . q{::} . $set_property }= _create_set_accessor($property);

    $PROPERTIES_FOR{$caller}->{$property} = 1;

    return;
}

sub _create_get_accessor {
    my ($property, $isa) = @_;

    return sub {
        my $self = shift;

        if (@_) {
            require Carp;
            Carp::croak("You tried to set a value with $property(). Did "
                    ."you mean set_$property() ?");
        }

        if (!exists $self->{$property}) {
            $self->{$property} =
                ref $isa eq 'CODE'
                ? $isa->()
                : $isa;
        }

        return $self->{$property};
    };
}

sub _create_set_accessor {
    my ($property) = @_;

    return sub  {
        my ($self, $value) = @_;
        $self->{$property} = $value;
        return;
        }
}

sub isa_String { ## no critic
    my ($default_value) = @_;

    return sub {

        return defined $default_value
            ? $default_value
            : q{};
    };
}

sub isa_Int    { ## no critic
    my ($default_value) = @_;

    return sub {

        return defined $default_value
            ? $default_value
            : 0;
    };
}

sub isa_Array  { ## no critic
    my @default_values = @_;

    return sub {

        return scalar @default_values
            ? \@default_values
            : [];
    };
}

sub isa_Hash   { ## no critic
    my %default_values = @_;

    return sub {

        return scalar keys %default_values
            ? \%default_values
            : {};

        # have to test if there are any entries in the hash
        # so we return a new anonymous hash if it ain't.

    };
}

sub isa_Data   { ## no critic
    return sub {
        return;
    };
}

sub isa_Object { ## no critic
    return sub {
        return;
    };
}

1;

__END__

=begin wikidoc

= NAME

Class::Dot - Simple way of creating accessor methods.

= VERSION

This document describes Getopt::LL version v%%VERSION%%

= SYNOPSIS

    package Animal::Mammal::Carnivorous::Cat;

    use Class::Dot qw( :std );

    # A cat's properties, with their default values and type of data.
    property gender      => isa_String('male');
    property memory      => isa_Hash;
    property state       => isa_Hash(instinct => 'hungry');
    property family      => isa_Array;
    property dna         => isa_Data;
    property action      => isa_Data;
    property colour      => isa_Int(0xfeedface);
    property fur         => isa_Array('short');

     sub new {
        my ($class, $gender) = @_;
        my $self    = { }; # Must be anonymous hash for Class::Dot to work.
        bless $self, $class;

        $self->set_gender($gender);

        warn sprintf('A new cat is born, it is a %s. Weeeeh!',
            $self->gender
        );

        return $self;
    }

    sub run {
        while (1) {
            die if $self->state->{dead};
        }
    }

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

    

    
        

= DESCRIPTION

A simple module for creating accessor methods with default types.

= SUBROUTINES/METHODS

== CLASS METHODS

=== {property($property, $default_value)}
=for apidoc VOID = Class::Dot::property(string $property, data $default_value)

Example:

    property foo => isa_String('hello world');

    property bar => isa_Int(303);

will create the methods:

    foo( )
    set_foo($value)

    bar( )
    set_bar($value)

with default return values -hello world- and -303-.

=== {isa_String($default_value)}
=for apidoc CODEREF = Class::Dot::isa_String(data|CODEREF $default_value)

The property is a string.

=== {isa_Int($default_value)}
=for apidoc CODEREF = Class::Dot::isa_Int(int $default_value)

The property is a number.

=== {isa_Array(@default_values)}
=for apidoc CODEREF = Class::Dot::isa_Array(@default_values)

The property is an array.

=== {isa_Hash(%default_values)}
=for apidoc CODEREF = Class::Dot::isa_Hash(@default_values)

The property is an hash.

=== {isa_Object($kind)}
=for apidoc CODEREF = Class::Dot::isa_Object(string $kind)

The property is a object.
(Does not really set a default value.).

=== {isa_Data()}
=for apidoc CODEREF = Class::Dot::isa_Data()

The object is of a not yet defined data type.

== INSTANCE METHODS

=== {->properties_for_class($class)}
=for apidoc HASHREF = Class::Dot->properties_for_class(_CLASS|BLESSED $class)

Return the list of properties for a class/object that uses the powers.

== PRIVATE CLASS METHODS

=== {_create_get_accessor($property, $default_value)}
=for apidoc CODEREF = Class::Dot::_create_get_accessor(string $property, data|CODEREF $default_value)

Create the set accessor for a property.
Returns a code reference to the new setter method.
It has to be installed into the callers package afterwards.

=== {_create_set_accessor($property)
=for apidoc CODEREF = Class::Dot::_create_set_accessor(string $property)

Create the get accessor for a property.
Returns a code reference to the new getter method.
It has to be installed into the callers package afterwards.

= DIAGNOSTICS

== * You tried to set a value with {foo()}. Did you mean {set_foo()}

Self-explained?


= CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

= DEPENDENCIES

* [version]

= INCOMPATIBILITIES

None known.

= BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
[bug-getopt-ll@rt.cpan.org|mailto:bug-getopt-ll@rt.cpan.org], or through the web interface at
[CPAN Bug tracker|http://rt.cpan.org].

= SEE ALSO

== [Class::InsideOut]

= AUTHOR

Ask Solem, [ask@0x61736b.net].


= LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem [ask@0x61736b.net|mailto:ask@0x61736b.net].

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

= DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=end wikidoc

# Local variables:
# vim: ts=4

