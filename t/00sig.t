use lib 'inc';
use Test::More;
use Test::Signature;

if (eval 'use Module::Signature 0.66; 1')
{
	plan tests => 1;
	&signature_ok;
}
else
{
	plan skip_all =>'Need Module::Signature >= 0.66';
}
