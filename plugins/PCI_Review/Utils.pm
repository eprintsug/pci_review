package PCI_Review::Utils;

use LWP::UserAgent;
use JSON;
use Encode;

use strict;

sub get_pci_requests
{
    my( $session, $eprint ) = @_;

    return $session->dataset( "ldn" )->search(
        filters => [
            { meta_fields => [qw( subject_dataset )], value => "eprint" },
            { meta_fields => [qw( subject_id )], value => $eprint->id },
            { meta_fields => [qw( to )], value => "( ".join( " ", keys( $session->config( "ldn_inboxes", "pci_review" ) ) ) . " )", match => 'EQ', merge => 'ANY' },
        ],
        custom_order => "-timestamp",
    );
}

1;
