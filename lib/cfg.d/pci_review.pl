$c->{plugins}{"PCI_Review::Utils"}{params}{disable} = 0;
$c->{plugins}{"Screen::EPrint::PCIRequestReview"}{params}{disable} = 0;

$c->{ldn_inboxes}->{pci_review} = {
    'pci_evolbiol' => 'https://evolbiol.peercommunityin.org/', 
    'pci_ecology' => 'https://ecology.peercommunityin.org/',
    'pci_paleo' => 'https://paleo.peercommunityin.org/',
    'pci_neuro' => 'https://neuro.peercommunityin.org/',
    'pci_zool' => 'https://zool.peercommunityin.org/',
    'pci_genomics' => 'https://genomics.peercommunityin.org/',    
    'pci_mcb' => 'https://mcb.peercommunityin.org/',    
    'pci_animsci' => 'https://animsci.peercommunityin.org/',    
    'pci_forestwoodsci' => 'https://forestwoodsci.peercommunityin.org/',    
    'pci_archaeo' => 'https://archaeo.peercommunityin.org/',    
    'pci_networksci' => 'https://networksci.peercommunityin.org/',    
    'pci_ecotoxenvchem' => 'https://ecotoxenvchem.peercommunityin.org/',    
    'pci_infections' => 'https://infections.peercommunityin.org/',    
    'pci_microbiol' => 'https://microbiol.peercommunityin.org/',    
    'pci_healthmovsci' => 'https://healthmovsci.peercommunityin.org/',    
    'pci_rr' => 'https://rr.peercommunityin.org/',    
    'pci_orgstudies' => 'https://orgstudies.peercommunityin.org/',    
};

# Trigger for refreshing summary pages from PCI announce reviews/endorsements
$c->add_dataset_trigger( 'ldn', EPrints::Const::EP_TRIGGER_CREATED, sub{

    my( %params ) = @_;

    my $repo = $params{repository};
    my $ldn = $params{dataobj};    

    # get the ldn this is in response to
    return undef unless( $ldn->is_set( "in_reply_to" ) );
    my $original_ldn = $ldn->get_in_reply_to_ldn;
    return undef unless defined $original_ldn;

    # get the eprint this is about
    return undef unless( $original_ldn->is_set( "subject_dataset" ) && $original_ldn->value( "subject_dataset" ) eq "eprint" );
    return undef unless $original_ldn->is_set( "subject_id" );

    my $eprint = $repo->dataset( "eprint" )->dataobj( $original_ldn->value( "subject_id" ) );
    return undef unless defined $eprint;

    # check origin and see if it's a PCI
    my $origin = $ldn->get_content_value( "origin" );
    return undef if !defined $origin;

    # get the ldn inboxes...
    my $inboxes = $repo->dataset( "ldn_inbox" )->search(
        filters => [
            { meta_fields => [qw( id )], value => keys( %{$repo->config( "ldn_inboxes", "pci_review" )} ), match => 'EQ', merge => 'ANY' },
        ]
    );

    my @endpoints;
    $inboxes->map( sub {
        (undef, undef, my $ldn_inbox ) = @_;
        push @endpoints, $ldn_inbox->value( "endpoint" );
    } );

    if( grep { $origin->{inbox} =~ /^$_\/?$/ } values( @endpoints ) )
    {
        # this is an ldn from a PCI inbox
        # what kind of response is it
        my $type = $ldn->value( "type" );
        if( $type eq "AnnounceReview" || $type eq "AnnounceEndorsement" )
        {
            # regenerate the static page for this eprint
            $eprint->generate_static;       
        }
    }
} );

# Extra EPrint DataObj functionality
{
    package EPrints::DataObj::EPrint;

    # Returns the current PCI status from the latest exchange of LDNs
    sub get_pci_status
    {
        my( $self ) = @_;

        my $latest = $self->get_latest_pci_ldn;

        if( defined $latest )
        { 
            return $latest->get_pci_status;
        }
        else
        {
            return undef;
        }
    }

    sub get_latest_pci_ldn
    {
        my( $self ) = @_;

        my $repo = $self->{session}->get_repository;

        # get the PCI LDNs for this EPrint
        my $ldns = $self->{processor}->{ldns} = PCI_Review::Utils::get_pci_requests( $repo, $self );
        if( $ldns && $ldns->count > 0 )
        {
            # specifically get the latest one
            my $latest = $ldns->item( 0 );
        }
        else
        {
            return undef;
        }
    }
};

# Extra LDN DataObj functionality
{
    package EPrints::DataObj::LDN;

    # Returns the current PCI status from the latest exchange of LDNs
    sub get_pci_status
    {
        my( $self ) = @_;
    
        # look for the latest response
        my $latest_response = $self->get_latest_response;
    
        # if we have a response, work out what the last situation is
        if( $latest_response )
        {
            return $latest_response->value( "type" );
        }
        else # we have sent an LDN to a PCI, but haven't had a response... so what's happening
        {
            if( $self->value( "status" ) eq "sent" )
            {
                return "pending";
            }   
            else
            {
                return "fail";
            }
        }
    }
};

# Compiled Script functionality to do checks for reviews in citations
{
package EPrints::Script::Compiled;
use strict;

sub run_is_pci_reviewed
{
    my( $self, $state, $eprint ) = @_;

    my $session = $state->{session};

    $eprint = $eprint->[0];

    my $reviewed = 0;

    # get our current status
    my $status = $eprint->get_pci_status;

    print STDERR "status: $status\n";

    if( $status eq "AnnounceEndorsement" )
    {
        $reviewed = 1;       
    }
    return [ $reviewed, "BOOLEAN" ];
}

sub run_pci_review_link
{
    my( $self, $state, $eprint ) = @_;

    my $session = $state->{session};

    $eprint = $eprint->[0];
 
    my $latest_pci = $eprint->get_latest_pci_ldn;
    my $latest_response = $latest_pci->get_latest_response;

    my $review = $latest_response->get_content_value( "object" )->{id};

    my $xml = $session->xml;
    my $link = $xml->create_element( "a", href => $review );
    $link->appendChild( $session->make_text( $review ) );

    return [ $link, "XHTML" ];
}

}
