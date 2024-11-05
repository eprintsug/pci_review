$c->{plugins}{"PCI_Review::Utils"}{params}{disable} = 0;
$c->{plugins}{"Screen::EPrint::PCIRequestReview"}{params}{disable} = 0;

$c->{ldn_inboxes}->{pci_review} = {
    'pci_evolbiol' => 'https://evolbiol.peercommunityin.org/', 
    'pci_paleo' => 'https://paleo.peercommunityin.org/', 
    'pci_neuro' => 'https://neuro.peercommunityin.org/'
};

# TODO...
# 1) Virtualfield that provides an EPrints' LDNs....
# 2) Virtualfield that provides an end of the line status (by following the LDN graph)
# a) Get the most recent LDN we have sent for the eprint and get the latest one that replied to it - see https://coar-notify.net/catalogue/workflows/repository-pci/ for possible outcomes
# 3) Simplified UX - submission for review is a line in Actions, that shows either a summary with otpion to submit
# 4) Screen for admins to show the LDN graph (i.e. screen as is at the moment)
# 5) New EPrint preprint type (can we do this in an ingredient)
# 6) Compiled Script addition for adding to the summary page to display a banner!

=comment
$c->add_dataset_trigger( 'ldn', EPrints::Const::EP_TRIGGER_CREATED, sub{
    my( %params ) = @_;

    my $repo = $params{repository};
    my $ldn = $params{dataobj};    

    # check origin and see if it's a PCI
    my $origin = $ldn->get_content_value( "origin" );
    return undef if !defined $origin;

    # get the ldn inboxes...
    my $inboxes = $repo->dataset( "ldn_inbox" )->search(
        filters => [
            { meta_fields => [qw( id )], value => keys( $repo->config( "ldn_inboxes", "pci_review" ) ), match => 'EQ', merge => 'ANY' },
        ]
    );

    my @endpoints;
    $inboxes->map( sub {
        (undef, undef, my $ldn_inbox ) = @_;
        push @endpoints, $ldn_inbox->value( "endpoint" );
    } );

    if( grep { $origin->{inbox} =~ /^$_\/?$/ } values( @endpoints ) )
    {
        # this is an ldn from a PCI inbox!
    }
} );
=cut

# Extra EPrint DataObj functionality
{
    package EPrints::DataObj::EPrint;

    # Returns the current PCI status from the latest exchange of LDNs
    sub get_pci_status
    {
        my( $self ) = @_;

        my $repo = $self->{session}->get_repository;

        my $ds = $repo->dataset( "message" );

        # get the PCI LDNs for this EPrint
        my $ldns = $self->{processor}->{ldns} = PCI_Review::Utils::get_pci_requests( $repo, $self );
        if( $ldns && $ldns->count > 0 )
        {
            # specifically get the latest one
            my $latest = $ldns->item( 0 );
 
            return $latest->get_pci_status;
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
