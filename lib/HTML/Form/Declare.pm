package HTML::Form::Declare;

use warnings;
use strict;
use HTML::Form::Declare::Object;

=head1 NAME

HTML::Form::Declare - Object description of the form elements

=head1 VERSION

Version 0.03_l

=cut

our $VERSION = '0.03_l';


=head1 SYNOPSIS

	use HTML::Form::Declare;

	## Login generator
	sub generate_login {...};

	## Validators
	sub check_login {...};
	sub check_password_with_confirm {...};
	sub check_pass {};


	my $conf = {
		lists_of_containers => ['groups'],
		parent_fields => ['required'],
	};
	my $fields = {
		config       => $config,
		method       => 'POST',
		id			 => 'form_registration',
		name         => 'form_registration',
		prefix       => 'my_form_',
		required     => 1,
		filter       => 2**1 | 2**3,
		groups       => [
			{
				name      => { 2**1 => 'Vhod', 2**3 => 'Registratsionnye dannye' },
				order     => 10,
				prefix    => { 2**1 => 'login:', 2**3 => 'reg:' },
				fields    => [
					{
						label        => 'Login',
						formfield    => 'login',
						object_name  => 'login',
						validate     => { 2**3 => \&check_login },
						value        => { 2**3 => generate_login() },
						type         => { 2**3 => 'login', 2**1 => 'text' },
						comment      => { 2**3 => 'Naprimer: ' . generate_login() },
						order        => 10,
					},
					{
						validate     => \&check_password_with_confirm,
						type         => 'password_with_confirm',
						formfield    => 'passowrd',
						object_name  => 'passwd',
						order        => 20,
						fields    => [
							{
								label        => 'Parol'',
								formfield    => 'passowrd_main',
								validate     => \&check_pass,
								type         => 'password',
								order        => 10,
							},
							{
								label        => 'Povtorite parol'',
								formfield    => 'password_confirm',
								type         => 'password',
								filter       => 2**3,
								order        => 20,
							},
						],
					},
				],
			},
		],
	};


	my $filter = 2**3;
	my $form = HTML::Form::Declare->generate_form_fields( $fields, $filter, { global_prefix=>'new:' }, $replace );

	## Return structure to TT

=head1 DESCRIPTION

	Create a structure of form. Call L<generate_form_fields> method and obtain the structure of the form by HTML::Form::Declare::Object.
    $filter - bit filter
    [, bit filter[, overdetermined parameters of congig[, options for replacing]]]

=head1 FUNCTIONS

=head2 generate_form_fields

=cut

sub generate_form_fields {
	my ( $proto, $form, $filter, $set_prms, $replace ) = @_;

	## Create config
	$form->{config} = HTML::Form::Declare::Object::Config->new( $form->{config} );
	my $self = HTML::Form::Declare::Object->create( $form );
	if ( ref $set_prms eq 'HASH' ) { $self->{$_} = $set_prms->{$_} for keys %$set_prms };
	$self->create_childs( $filter, $replace );
	$self->sort_by_order();
	return $self;
}

=head1 AUTHOR

shv, C<< <shv@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-form-declare at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Form-Declare>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Form::Declare


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Form-Declare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Form-Declare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Form-Declare>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Form-Declare>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 shv, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of HTML::Form::Declare
