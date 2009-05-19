#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'HTML::Form::Declare::Object' );
	use_ok( 'HTML::Form::Declare' );
}

diag( "Testing HTML::Form::Declare $HTML::Form::Declare::VERSION, Perl $], $^X" );
diag( "Testing HTML::Form::Declare::Object $HTML::Form::Declare::Object::VERSION, Perl $], $^X" );
