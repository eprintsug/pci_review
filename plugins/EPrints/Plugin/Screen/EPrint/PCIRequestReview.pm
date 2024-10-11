=head1 NAME

EPrints::Plugin::Screen::EPrint::PCIRequestReview

=cut

package EPrints::Plugin::Screen::EPrint::PCIRequestReview;

@ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

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

#sub can_be_viewed
#{
#	my( $self ) = @_;
#
#	return 1;
#}

sub allow_request_review
{
	my( $self ) = @_;

	return 1; #$self->allow( "eprint/derive_version" );
}

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

	$frag->appendChild( $self->render_request_form );

	return $frag;
}

sub render_request_form
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $div = $xml->create_element( "div", class => "ep_block ep_sr_component" );

	my $title = $xml->create_element( "h2", id => "data_label" );
	$title->appendChild( $self->html_phrase( "data" ) );
	$div->appendChild( $title );

	my $help = $xml->create_element( "p", id => "data_help" );
        $help->appendChild( $self->html_phrase( "data_help" ) );
	$div->appendChild( $help );

	my $form = $div->appendChild( $self->{processor}->screen->render_form( "request_review" ) );
	$form->appendChild($repo->render_option_list( 
			name => 'pci_community', 
			values => ["evol_biol", "ecology"], 
			labels => {evol_biol => "PCI Evol Bio", ecology => "PCI Ecology"}
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
        my $ds = $session->dataset( "ldn" );
        my $ldn = EPrints::DataObj::LDN->create_from_data(
          $session,
          {
              from => $session->get_conf("base_url"),
              to => $session->param("pci_community"),
              type => "OfferEndorsement",
          },
          $ds
       );

       my @docs = $eprint->get_all_documents;
       my $document = $docs[0];
       print STDERR "DOC: ".$document."\n";
       my $user = $self->{session}->current_user;
       my $json = $ldn->_create_payload($eprint,$user,$session->param("pci_community"),$document);
       print STDERR "JSON : $json\n";
       $ldn->set_value("content", $json);
       $ldn->commit;

	$self->{processor}->add_message( "message",
		$self->html_phrase( "success" ) );

}

1;

