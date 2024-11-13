$c->{plugins}{"PCI_Review::Utils"}{params}{disable} = 0;
$c->{plugins}{"Screen::EPrint::PCIRequestReview"}{params}{disable} = 0;

$c->{ldn_inboxes}->{pci_review} = {
    'pci_evolbiol' => 'https://evolbiol.peercommunityin.org/', 
    'pci_paleo' => 'https://paleo.peercommunityin.org/', 
    'pci_neuro' => 'https://neuro.peercommunityin.org/'
};

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
