$c->{plugins}{"PCI_Review::Utils"}{params}{disable} = 0;
$c->{plugins}{"Screen::EPrint::PCIRequestReview"}{params}{disable} = 0;

$c->{ldn_inboxes}->{pci_review} = {
    'pci_evolbiol' => 'https://evolbiol.peercommunityin.org/', 
    'pci_paleo' => 'https://paleo.peercommunityin.org/', 
    'pci_neuro' => 'https://neuro.peercommunityin.org/'
};

# PCI EPrints Fields - VIRTUAL FIELD
$c->add_dataset_field( "eprint",
    {
        name => 'pci_status',
        type => 'status',
    }

# TODO...
# 1) Virtualfield that provides an EPrints' LDNs....
# 2) Virtualfield that provides an end of the line status (by following the LDN graph)
# a) Get the most recent LDN we have sent for the eprint and get the latest one that replied to it - see https://coar-notify.net/catalogue/workflows/repository-pci/ for possible outcomes
# 3) Simplified UX - submission for review is a line in Actions, that shows either a summary with otpion to submit
# 4) Screen for admins to show the LDN graph (i.e. screen as is at the moment)
# 5) New EPrint preprint type (can we do this in an ingredient)
# 6) Compiled Script addition for adding to the summary page to display a banner!


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
        print STDERR "yeah\n";
    }
} );
