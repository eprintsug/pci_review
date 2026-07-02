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
            { meta_fields => [qw( subject_id )], value => "( ".join( " ", get_eprint_ids($session, $eprint) )." )", match => 'EQ', merge => 'ANY' },
            { meta_fields => [qw( in_reply_to )], value => undef },
            #{ meta_fields => [qw( to )], value => "( ".join( " ", keys( %{$session->config( "ldn_inboxes", "pci_review" )} ) ) . " )", match => 'EQ', merge => 'ANY' },
        ],
        custom_order => "-ldnid",
    );
}

sub get_eprint_ids
{
    my( $session, $eprint ) = @_;
    if ( $eprint->is_set("succeeds") ) {
        my $previous_eprint = $session->eprint( $eprint->get_value("succeeds") );
        if ( defined $previous_eprint ) {
            return ($eprint->id, get_eprint_ids($session, $previous_eprint));
        }
    }
    return ($eprint->id);
}

1;
