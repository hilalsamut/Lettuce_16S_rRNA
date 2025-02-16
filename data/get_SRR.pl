#!/usr/bin/perl

use strict;
use warnings;
use Parallel::ForkManager;  # You may need to install this module: `cpanm Parallel::ForkManager`

my @txt = glob "*SRR*";

foreach my $filename (@txt) {
    open INPUT, "<", $filename;

    my $pm = Parallel::ForkManager->new(20);  # Number of parallel processes

    while (defined(my $line = <INPUT>)) {
        chomp($line);

        my $pid = $pm->start and next;  # Forks child process
        system("fastq-dump --gzip --split-files $line");
        $pm->finish;  # Ends child process
    }

    close INPUT;
    $pm->wait_all_children;  # Wait for all child processes to finish
}


