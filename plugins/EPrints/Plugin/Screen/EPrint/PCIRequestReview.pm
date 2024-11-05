=head1 NAME

EPrints::Plugin::Screen::EPrint::PCIRequestReview

=cut

package EPrints::Plugin::Screen::EPrint::PCIRequestReview;

@ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

use PCI_Review::Utils;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	#	$self->{priv} = # no specific priv - one per action

	$self->{actions} = [qw/ request_review /];

	$self->{appears} = [ { place => "eprint_actions",
			       position => 500, },
	];

	$self->{disable}  = 0;

	return $self;
}

sub properties_from
{
    my( $self ) = @_;

    my $repo = $self->repository;
    $self->SUPER::properties_from;

    my $eprint = $self->{processor}->{eprint};

    $self->{processor}->{status} = $eprint->get_pci_status;

    print STDERR "status: " . $self->{processor}->{status} . "\n";

    $self->{processor}->{ldns} = PCI_Review::Utils::get_pci_requests( $repo, $eprint );
}

sub can_be_viewed
{
	my( $self ) = @_;

    # the eprint must be in the live archive
    return 0 unless $self->{processor}->{eprint}->value( "eprint_status" ) eq "archive";


    # and it must have an openly accessible full text
    return 0 unless $self->{processor}->{eprint}->value( "full_text_status" ) eq "public";

	return 1; #$self->allow( "eprint/derive_version" );
}

#sub allow_request_review
#{
#	my( $self ) = @_;
#    print STDERR "allow_request_review\n";
#    # the eprint must be in the live archive
#    return 0 unless $self->{processor}->{eprint}->value( "status" ) eq "archive";
#    print STDERR "yes allow\n";
#	return 1; #$self->allow( "eprint/derive_version" );
#}

#sub about_to_render 
#{
#	my( $self ) = @_;
#
#	$self->EPrints::Plugin::Screen::EPrint::View::about_to_render;
#}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $frag = $xml->create_document_fragment;

	$frag->appendChild( $self->html_phrase( "help" ) );

    # status
    if( defined $self->{processor}->{status} )
    {
        $frag->appendChild( $self->render_status );    
}

    # present option to request review if no status or last response was reject
    if( !defined $self->{processor}->{status} || $self->{processor}->{status} eq "Reject" || $self->{processor}->{status}eq "fail" )
    {
        # form
	    $frag->appendChild( $self->render_request_form );
    }
    
    # requests
    $frag->appendChild( $self->render_requests );

	return $frag;
}

sub render_status
{
    my( $self )= @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $div = $xml->create_element( "div", class => "ep_block ep_sr_component pci_status" );

    my $status = $self->{processor}->{status};
 	my $title = $xml->create_element( "h2", id => "status_label" );
    $title->appendChild( $self->html_phrase( "status" ) );
    $title->appendChild( $self->html_phrase( "pci_$status" ) );
   	$div->appendChild( $title );

    return $div;
}

sub render_request_form
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $div = $xml->create_element( "div", class => "ep_block ep_sr_component pci_request_review_form" );

	my $title = $xml->create_element( "h2", id => "data_label" );
	$title->appendChild( $self->html_phrase( "data" ) );
	$div->appendChild( $title );

	my $help = $xml->create_element( "p", id => "data_help" );
        $help->appendChild( $self->html_phrase( "data_help" ) );
	$div->appendChild( $help );

	my $form = $div->appendChild( $self->{processor}->screen->render_form( "request_review" ) );

	my @inboxes = keys %{$repo->get_conf("ldn_inboxes", "pci_review")};
	my %labels;
	foreach my $key(@inboxes){
	   $labels{$key} = $repo->phrase("pci_review/inbox:label_".$key);
	}

	$form->appendChild($repo->render_option_list( 
			name => 'pci_community', 
			values => \@inboxes,
			labels => \%labels
			) );

	#$form->appendChild( $self->render_actions );
	$form->appendChild( $repo->render_action_buttons(
		request_review => $repo->phrase( "Plugin/Screen/PCIRequestReview:action_request" ),
	) );

	return $div;
}


sub action_request_review
{
    my( $self ) = @_;

    my $session = $self->{session};
    my $eprint =  $self->{processor}->{eprint};
    my $ldn_ds = $session->dataset( "ldn" );

    my $ldn = EPrints::DataObj::LDN->create_from_data(
        $session,
        {
            from => $session->get_conf("base_url"),
            to => $session->param("pci_community"),
            type => "OfferEndorsement",
            subject_id => $eprint->id,
            subject_dataset => "eprint",
        },
        $ldn_ds
    );

    my @docs = $eprint->get_all_documents;
    my $document = $docs[0];
    my $user = $self->{session}->current_user;
    $ldn->create_payload_and_send(
        $eprint, # OBJECT
        $user, # ACTOR
        $document # SUB OBJECT
    );


    $self->{processor}->add_message( "message",
    $self->html_phrase( "success" ) );

}

sub render_requests
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $div = $xml->create_element( "div", class => "ep_block ep_sr_component pci_requests" );

	my $title = $xml->create_element( "h2", id => "requests" );
	$title->appendChild( $self->html_phrase( "requests" ) );
	$div->appendChild( $title );

	my $help = $xml->create_element( "p", id => "requests_help" );
    $help->appendChild( $self->html_phrase( "requests_help" ) );
	$div->appendChild( $help );

    $self->{processor}->{ldns}->map( sub {
        (undef, undef, my $ldn ) = @_;

        my $status = $ldn->get_pci_status;

        $div->appendChild( my $ldn_div = $xml->create_element( "div", class => "pci_ldn_request pci_$status" ) );
        $ldn_div->appendChild( $ldn->render_citation( "pci_ldn" ) );

        # get responses
        my $responses = $ldn->get_responses;
        if( $responses )
        {        
            $responses->map( sub {
                (undef, undef, my $response ) = @_;
                $ldn_div->appendChild( my $response_div = $xml->create_element( "div", class => "pci_ldn_response" ) );
                $response_div->appendChild( $response->render_citation( "pci_ldn" ) );
            } );
        }
    } );

	return $div;
}

1;

