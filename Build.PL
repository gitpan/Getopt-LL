# $Id: Build.PL,v 1.3 2007/06/27 12:05:35 ask Exp $
# $Source: /opt/CVS/Getopt-LL/Build.PL,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.3 $
# $Date: 2007/06/27 12:05:35 $
use strict;
use warnings;

sub BEGIN {
    use File::Spec;
    use FindBin qw($Bin);
    my $inc = File::Spec->catdir($Bin, 'inc');
    unshift @INC, $inc;
}

use Module::Build::Getopt::LL;

# ##########################################################

# Configuration for this script is done in the config.ph file.
our $BUILD_CONFIGFILE = 'config.ph';

# ##########################################################



sub YES { 1 };
sub NO  { 0 };

$ENV{DEVEL_COVER_OPTIONS} = '-ignore,blib/Class/InsideOut/Policy/Modwheel.pm';
my $builder = Module::Build::Getopt::LL->new(
    module_name          => 'Getopt::LL',
    license              => 'perl',
    dist_author          => 'Ask Solem <ASKSH@cpan.org>',
    all_from             => 'lib/Getopt/LL.pm',
    dynamic_config       => NO,
    sign                 => NO, # asksh: have to find out why my signature fails.
    create_makefile_pl   => 'traditional',
    create_readme        => YES,
    recursive_test_files => YES,
    requires             => {
        'version'                               => 0,
    },
    recommends           => {
        'Test::Pod'             => 1.22,    # Last significant bug-change.
        'Pod::Coverage'         => 0.18,       
        'Test::Pod::Coverage'   => 1.08,    # Last significant bug-change.
        'Test::Exception'       => 0.25,
        'Perl::Critic'          => 1.051,
        'Test::Perl::Critic'    => 1.0,
        'Test::YAML::Meta'      => 0.04,
        'IO::Capture::Stderr'   => 0,
       'Test::Kwalitee'        => 0.30,
    },
    build_requires       => {
     'Test::Simple'            => 0.42,    # 
    },
    add_to_cleanup       => [ qw(
        a.out
        test.pl
        test.c
        test.cpp
        test.m
        *.swp
        .gdb_history
        install.cache
        t/cache
        cache/
    ) ],
    meta_merge => {
        distribution_type   => 'Module',
    },
);

$builder->create_build_script( );
