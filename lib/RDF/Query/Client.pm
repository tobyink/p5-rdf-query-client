package RDF::Query::Client;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use RDF::Trine;
use URI::Escape;

our $VERSION = '0.05';

=head1 NAME

RDF::Query::Client - Get data from W3C SPARQL Protocol 1.0 servers

=head1 VERSION

0.05

=head1 SYNOPSIS

  use RDF::Query::Client;
  
  my $query = new RDF::Query::Client ("SELECT * WHERE {?s ?p ?o. ?o ?p ?s.}");
  my $iterator = $query->execute('http://example.com/sparql');
  while (my $row = $iterator->next) {
    print $row->{'s'}->as_string;
  }

=head1 METHODS

=over 4

=item C<< $query = RDF::Query::Client->new ( $sparql, \%opts ) >>

Returns a new RDF::Query::Client object for the specified C<$sparql>.
The object's interface is designed to be roughly compatible with RDF::Query
objects, though RDF::Query is not required by this module.

Options include:

=over 4

=item B<UserAgent> - an LWP::UserAgent to handle HTTP requests.

=back 

Unlike RDF::Query, where you get a choice of query language, the query language
for RDF::Query::Client is always 'sparql'. RDF::TrineShortcuts offers a way to perform
RDQL queries on remote SPARQL stores though (by transforming RDQL to SPARQL).

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

=item C<< $query->execute ( $endpoint, \%opts ) >>

C<$endpoint> is a URI object or string containing the endpoint
URI to be queried.

Options include:

=over 4

=item * B<UserAgent> - an LWP::UserAgent to handle HTTP requests.

=item * B<QueryMethod> - 'GET', 'POST' or undef (automatic).

=item * B<QueryParameter> - defaults to 'query'.

=item * B<AuthUsername> - HTTP Basic authorization.

=item * B<AuthPassword> - HTTP Basic authorization.

=item * B<Headers> - additional headers to include (hashref).

=item * B<Parameters> - additional GET/POST fields to include (hashref).

=back

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

=item C<< $query->get ( $endpoint, \%opts ) >>

Executes the query using the specified endpoint, and returns the first matching row
as a LIST of values. Takes the same arguments as C<< execute() >>.

=cut

sub get
{
	my $stream = execute( @_ );
	
	if (ref $stream)
	{
		if ($stream->is_bindings)
		{
			my $row = $stream->next;
			return $stream->binding_values;
		}
		if ($stream->is_graph)
		{
			my $st = $stream->next;
			return ($st->subject, $st->predicate, $st->object);
		}
		if ($stream->is_boolean)
		{
			my @rv;
			push @rv, 1 if $stream->get_boolean;
			return @rv;
		}
	}
	
	return undef;
}

=item C<< $query->as_sparql >>

Returns the query as a string in the SPARQL syntax.

=cut

sub as_sparql
{
	my $self = shift;
	return $self->{'query'};
}

=item C<< $query->useragent >>

Returns the LWP::UserAgent object used for retrieving web content.

=cut

sub useragent
{
	my $self = shift;
	return $self->{'ua'};
}

=item C<< $query->http_response >>

Returns the last HTTP Response the client experienced.

=cut

sub http_response
{
	my $self = shift;
	return $self->{'results'}->[-1]->{'response'};
}

=item C<< $query->error >>

Returns the last error the client experienced.

=cut

sub error
{
	my $self = shift;
	return $self->{'error'};
}

sub prepare { carp "Method not implemented\n"; }
sub execute_plan { carp "Method not implemented\n"; }
sub execute_with_named_graphs { carp "Method not implemented\n"; }
sub aggregate { carp "Method not implemented\n"; }
sub pattern { carp "Method not implemented\n"; }
sub sse { carp "Method not implemented\n"; }
sub algebra_fixup { carp "Method not implemented\n"; }
sub add_function { carp "Method not implemented\n"; }
sub supported_extensions { carp "Method not implemented\n"; }
sub supported_functions { carp "Method not implemented\n"; }
sub add_computed_statement_generator { carp "Method not implemented\n"; }
sub get_computed_statement_generators { carp "Method not implemented\n"; }
sub net_filter_function { carp "Method not implemented\n"; }
sub add_hook_once { carp "Method not implemented\n"; }
sub add_hook { carp "Method not implemented\n"; }
sub parsed { carp "Method not implemented\n"; }
sub bridge { carp "Method not implemented\n"; }
sub log { carp "Method not implemented\n"; }
sub logger { carp "Method not implemented\n"; }
sub costmodel { carp "Method not implemented\n"; }

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
		$method = (length $self->{'query'} > 600) ? 'POST' : 'GET';
	}
	
	my $param = $opts->{QueryParameter} || 'query';
	
	my $uri = '';
	my $cnt = '';
	if ($method eq 'GET')
	{
		$uri  = $endpoint . ($endpoint =~ /\?/ ? '&' : '?');
		$uri .= sprintf(
			"%s=%s",
			uri_escape($param),
			uri_escape($self->{'query'})
			);
		if ($opts->{Parameters})
		{
			foreach my $field (keys %{$opts->{Parameters}})
			{
				$uri .= sprintf(
					"&%s=%s",
					uri_escape($field),
					uri_escape($opts->{Parameters}->{$field}),
					);
			}
		}
	}
	elsif ($method eq 'POST')
	{
		$uri  = $endpoint;
		$cnt  = sprintf(
			"%s=%s",
			uri_escape($param),
			uri_escape($self->{'query'})
			);
		if ($opts->{Parameters})
		{
			foreach my $field (keys %{$opts->{Parameters}})
			{
				$cnt .= sprintf(
					"&%s=%s",
					uri_escape($field),
					uri_escape($opts->{Parameters}->{$field}),
					);
			}
		}
	}
	
	my $req = HTTP::Request->new($method, $uri);
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($cnt);
	$req->authorization_basic($opts->{AuthUsername}, $opts->{AuthPassword})
		if defined $opts->{AuthUsername};
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

=head1 SECURITY

The C<execute> and C<get> methods allow AuthUsername and
AuthPassword options to be passed to them for HTTP Basic authentication.
For more complicated authentication (Digest, OAuth, Windows, etc),
it is also possible to pass these methods a customised LWP::UserAgent.

If you have the Crypt::SSLeay package installed, requests to HTTPS
endpoints should work. It's possible to specify a client X.509
certificate (e.g. for FOAF+SSL authentication) by setting particular
environment variables. See L<Crypt::SSLeay> documentation for details.

=head1 BUGS

Probably.

=head1 SEE ALSO

=over 4

=item * L<RDF::Trine>, L<RDF::Trine::Iterator>

=item * L<RDF::Query>

=item * L<RDF::TrineShortcuts>

=item * L<LWP::UserAgent>

=item * http://www.w3.org/TR/rdf-sparql-protocol/

=item * http://www.w3.org/TR/rdf-sparql-query/

=item * http://www.perlrdf.org/

=back

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
