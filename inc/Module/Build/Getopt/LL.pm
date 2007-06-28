# $Id: LL.pm,v 1.1 2007/06/20 18:40:40 ask Exp $
# $Source: /opt/CVS/Getopt-LL/inc/Module/Build/Getopt/LL.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/06/20 18:40:40 $
package Module::Build::Getopt::LL;
use strict;
use warnings;
use base 'Module::Build';

sub ACTION_wikidoc {
    my $self = shift;
    eval 'use Pod::WikiDoc';
    if ($@ eq q{}) {
        my $parser = Pod::WikiDoc->new(
            {   comment_blocks  => 1,
                keywords        => {VERSION => $self->dist_version,},
            }
        );
        for my $source_file (keys %{ $self->find_pm_files() }) {
            my $output_file = $self->pm_file_to_pod_file($source_file);
            $parser->filter(
                {   input  => $source_file,
                    output => $output_file,
                }
            );
            $self->log_info("Creating $output_file\n");
            $self->_add_to_manifest('MANIFEST', $output_file);
        }
    }
    else {
        $self->log_warn(
            'Pod::WikiDoc not available. Skipping wikidoc.'
        );
    }
}

sub ACTION_test {
    my $self = shift;
    my $missing_pod;
    for my $source_file (keys %{ $self->find_pm_files() }) {
        my $output_file = $self->pm_file_to_pod_file($source_file);
        if (! -e $output_file) {
            $missing_pod++;
        }
    }

    if ($missing_pod) {
        $self->depends_on('wikidoc');
        $self->depends_on('build');
    }

    return $self->SUPER::ACTION_test(@_);
}

sub ACTION_testpod {
    my $self = shift;
    $self->depends_on('wikidoc');
    return $self->SUPER::ACTION_testpod(@_);
}

sub ACTION_distdir {
    my $self = shift;
    $self->depends_on('wikidoc');
    return $self->SUPER::ACTION_distdir(@_);
}


sub pm_file_to_pod_file {
    my ($self, $filename) = @_;
    $filename =~ s{\.pm}{.pod}xms;
    return $filename;
}

sub log_warn {
    my ($self, @messages) = @_;

    for my $message (@messages) {
        chomp $message;
        $message .= qq{\n};
    }

    return $self->SUPER::log_warn(@messages);
}

1;
