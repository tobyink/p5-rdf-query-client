package RDF::Query::Client;

use 5.010000;
use strict;
use warnings;

use LWP::UserAgent;
use RDF::Trine;
use URI::Escape;

our $VERSION = '0.01';

=head1 NAME

RDF::Query::Client - Client for W3C SPARQL Protocol 1.0

=head1 VERSION

0.01

=head1 SYNOPSIS

  use RDF::Query::Client;
  
  my $query = new RDF::Query::Client ("SELECT * WHERE {?s ?p ?o. ?o ?p ?s.}");
  my $iterator = $query->execute('http://example.com/sparql');
  while (my $row = $iterator->next) {
    print $row->{'s'}->as_string;
  }

=head1 METHODS

=over 4

=item C<< new ( $query, \%opts ) >>

Returns a new RDF::Query::Client object for the specified C<$query>.
The object's interface is designed to be roughly compatible with RDF::Query
objects. The query language is always 'sparql'.

Options include:

    * UserAgent - an LWP::UserAgent to handle HTTP requests.

=cut

sub new
{
	my $class = shift;
	my $query = shift;
	my $opts  = shift;
	
	my $self = bless {
		'query'      => $query ,
		'ua'         => $opts->{UserAgent} ,
		'results'    => [] ,
		'error'      => undef ,
	}, $class;
	
	return $self;
}

=item C<< execute ( $endpoint, \%opts ) >>

C<$endpoint> is a URI object or string containing the endpoint
URI to be queried.

Options include:

    * UserAgent - an LWP::UserAgent to handle HTTP requests.
    * QueryMethod - 'GET', 'POST' or undef (automatic).
    * QueryParameter - defaults to 'query'.
    * Headers - additional headers to include (hashref).

Returns undef on error; an RDF::Trine::Iterator if called in a
scalar context; an array obtained by calling C<get_all> on the
iterator if called in list context.

=cut

sub execute
{
	my $self     = shift;
	my $endpoint = shift;
	my $opts     = shift;
	
	my $ua = $opts->{UserAgent};
	unless (defined $ua)
	{
		$self->_prepare_ua;
		$ua = $self->useragent;
	}
	
	my $request = $self->_prepare_request($endpoint, $opts);
	
	my $response = $ua->request($request);
	push @{ $self->{'results'} }, { 'response' => $response };

	my $iterator = $self->_create_iterator($response);
	return undef unless defined $iterator;
	$self->{'results'}->[-1]->{'iterator'} = $iterator;
		
	if (wantarray)
	{
		return $iterator->get_all;
	}
	else
	{
		return $iterator;
	}
}

=item C<< as_sparql () >>

Returns the query as a string in the SPARQL syntax.

=cut

sub as_sparql
{
	my $self = shift;
	return $self->{'query'};
}

=item C<< useragent () >>

Returns the LWP::UserAgent object used for retrieving web content.

=cut

sub useragent
{
	my $self = shift;
	return $self->{'ua'};
}

=item C<< http_response () >>

Returns the last HTTP Response the client experienced.

=cut

sub http_response
{
	my $self = shift;
	return $self->{'results'}->[-1]->{'response'};
}

=item C<< error () >>

Returns the last error the client experienced.

=cut

sub error
{
	my $self = shift;
	return $self->{'error'};
}

=item C<< get () >>

=item C<< prepare () >>

=item C<< execute_plan () >>

=item C<< execute_with_named_graphs () >>

=item C<< aggregate () >>

=item C<< pattern () >>

=item C<< sse () >>

=item C<< algebra_fixup () >>

=item C<< add_function () >>

=item C<< supported_extensions () >>

=item C<< supported_functions () >>

=item C<< add_computed_statement_generator () >>

=item C<< get_computed_statement_generators () >>

=item C<< net_filter_function () >>

=item C<< add_hook_once () >>

=item C<< add_hook () >>

=item C<< parsed () >>

=item C<< bridge () >>

=item C<< log () >>

=item C<< logger () >>

=item C<< costmodel () >>

Each of these currently returns undef. They are placeholders
for compatibility with RDF::Query.

=cut

sub get { }
sub prepare { }
sub execute_plan { }
sub execute_with_named_graphs { }
sub aggregate { }
sub pattern { }
sub sse { }
sub algebra_fixup { }
sub add_function { }
sub supported_extensions { }
sub supported_functions { }
sub add_computed_statement_generator { }
sub get_computed_statement_generators { }
sub net_filter_function { }
sub add_hook_once { }
sub add_hook { }
sub parsed { }
sub bridge { }
sub log { }
sub logger { }
sub costmodel { }

sub _prepare_ua
{
	my $self = shift;
	
	unless (defined $self->useragent)
	{
		$self->{'ua'} = LWP::UserAgent->new(
			'agent'        => 'RDF::Query::Client/'
			               .   $RDF::Query::Client::VERSION
								.   ' ' ,
			'max_redirect' => 2 ,
			'parse_head'   => 0 ,
			'protocols_allowed' => ['http','https'],
			);
		$self->{'ua'}->default_header('Accept' =>
			'application/sparql-results+xml, '.
			'application/rdf+xml, application/x-turtle, text/turtle');
	}
}

sub _prepare_request
{
	my $self     = shift;
	my $endpoint = shift;
	my $opts     = shift;
	
	my $method = uc $opts->{QueryMethod};
	if ($method !~ /^(get|post)$/i)
	{
		$method = (length $self->{'query'} > 800) ? 'POST' : 'GET';
	}
	
	my $param = $opts->{QueryParameter} || 'query';
	
	my $uri = '';
	my $cnt = '';
	if ($method eq 'GET')
	{
		$uri  = $endpoint . ($endpoint =~ /\?/ ? '&' : '?');
		$uri .= uri_escape($param);
		$uri .= "=";
		$uri .= uri_escape($self->{'query'});
	}
	elsif ($method eq 'POST')
	{
		$uri  = $endpoint;
		$cnt  = uri_escape($param);
		$cnt .= "=";
		$cnt .= uri_escape($self->{'query'});
	}
	
	my $req = HTTP::Request->new($method, $uri);
	$req->content($cnt);
	foreach my $k (keys %{$opts->{Headers}})
	{
		$req->header($k => $opts->{Headers}->{$k});
	}
	
	return $req;
}

sub _create_iterator
{
	my $self     = shift;
	my $response = shift;

	if ($response->code != 200)
	{
		$self->{'error'} = $response->message;
		return undef;
	}

	if ($response->content_type =~ /sparql.results/i)
	{
		return RDF::Trine::Iterator->from_string(
			$response->decoded_content);
	}
	elsif ($response->content_type =~ /rdf.xml/i)
	{
		my $model   = RDF::Trine::Model->new( RDF::Trine::Store->temporary_store );
		my $parser  = RDF::Trine::Parser::RDFXML->new;
		$parser->parse_into_model( $response->base, $response->decoded_content , $model );
		return $model->as_stream;
	}
	elsif ($response->content_type =~ /(n3|turtle|text.plain)/i)
	{
		my $model   = RDF::Trine::Model->new( RDF::Trine::Store->temporary_store );
		my $parser  = RDF::Trine::Parser::Turtle->new;
		$parser->parse_into_model( $response->base, $response->decoded_content , $model );
		return $model->as_stream;
	}		
	else
	{
		$self->{error} = "Return type not understood.";
		return undef
	}
}

1;

=back

=head1 SEE ALSO

=over 4

=item * L<RDF::Query>

=item * L<RDF::Trine>

=item * L<RDF::Query>

=item * http://www.w3.org/TR/rdf-sparql-protocol/

=item * http://www.perlrdf.org/

=back

=head1 AUTHOR

Toby Inkster, E<lt>mail@tobyinkster.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
