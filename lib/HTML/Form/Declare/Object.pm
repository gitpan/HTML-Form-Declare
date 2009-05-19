package HTML::Form::Declare::Object::Config;
use strict;

use Carp;
use Data::Dumper;

sub new {
    my $proto = shift;
    my $data = shift;
    my $config = {
        'formfield'           => 'formfield',
        'parent_fields'       => [],
        'filter'              => 'filter',
        'fields'              => 'fields',
        'lists_of_containers' => [],
        'default_filter'      => 'DEFAULT',
        'global_prefix'       => 'global_prefix',
        'prefix'              => 'prefix',
        'dependent'           => 'dependent',
        'dependent_on'        => 'dependent_on',
        'order'               => 'order',
    };
    $config->{$_} = $data->{$_} foreach keys %{$data || {}};
    my $self = bless $config, $proto;
    return $self;
}

sub parent_fields {
    my $self = shift;
    my @sys = ( 'config', $self->{filter}, $self->{global_prefix} );
    my @res = ( @{ $self->{parent_fields} || [] }, @sys );
    return wantarray ? @res : \@res;
}

sub lists_of_containers {
    my $self = shift;
    my @sys = ( $self->{fields} );
    my @res = ( @{ $self->{lists_of_containers} || [] }, @sys );
    return wantarray ? @res : \@res;
}

1;

package HTML::Form::Declare::Object;

use warnings;
use strict;

use Carp;
use Data::Dumper;

=head1 NAME

	HTML::Form::Declare::Object - Simple element of HTML::Form::Declare

=head1 VERSION

	Version 0.02_l

=cut

our $VERSION = '0.02_l';

=head1 SYNOPSIS

	use HTML::Form::Declare::Object;

	my $form = { ... };
	my $config = HTML::Form::Declare::Object::Config->new( $some_config );
	my $object = HTML::Form::Declare::Object->create( $form );

	## $object structure

=head1 FUNCTIONS

=head2 config

	return Config

=cut

sub config {
    my $self = shift;
    if ( $_[0] ) {
        $self->{config} = $_[0];
    }
    return $self->{config};
}

=head2 parent

	return parent of field

=cut

sub parent {
    my $self = shift;
    if ($_[0]) {
        $self->{parent} = $_[0];
    }
    return $self->{parent};
}

=head2 new

	Creator (use better create)

=cut

sub new {
    my $proto = shift;
    my $data = {@_};
    my $self = bless $data, $proto;
    $self->config( HTML::Form::Declare::Object::Config->new( $data->{config} ) ) unless ref $data->{config} eq 'HTML::Form::Declare::Object::Config';
    return $self;
}

=head2 create

	Creator with check input

=cut

sub create {
    my ($proto, $data) = @_;
    croak "HTML::Form::Declare::Object::create: Need HASH" unless ref $data eq 'HASH';
    return __PACKAGE__->new( %$data );
}

=head2 create_child

	Po dannym hesha sozdaet potomka ob'ekta

=cut

sub create_child {
    my ( $self, $data, $filter, $replace ) = @_;
    croak "HTML::Form::Declare::Object::create_child: Need HASH - ".Dumper($self, $data) unless ref $data eq 'HASH';
    #Sozdaem novyi hesh unasledovav polya predka
    my $clone;
    $clone->{$_} = $self->{$_} for $self->config->parent_fields;
    $clone = __PACKAGE__->create( $clone );
    #Ustanavlivaem peredannye polya, pereopredelyaya polya predka
    foreach ( keys %$data ) {
        $clone->{$_} = $data->{$_};
    }
    #Fil'truem polya
    $clone->filter_fields( $filter );
    $clone->{ $clone->config->{prefix} } = ( $self->{ $self->config->{prefix} } || '' ) . ( $clone->{ $clone->config->{prefix} } || '' ) if $self->{ $self->config->{prefix} } or $clone->{ $clone->config->{prefix} };
    #Menyaem polya na predustanovlennye (utochnyaem)
    if ( $replace and $replace->{ $clone->full_form_name() } ) {
        foreach ( keys %{ $replace->{ $clone->full_form_name() } } ) {
            $clone->{$_} = $replace->{ $clone->full_form_name() }->{$_}
        }
    }
    $clone->parent($self);
    return $clone;
}


=head2 create_childs

	Ischet spiski groups i fields i dlya kazhdyi element rekursivno preobrazuet v ob'ekt HTML::Form::Declare::Object
	$form_obj - ob'ekt HTML::Form::Declare::Object
	$filter - fil'tr
	Vozvrat - ob'ekt s preobrazovannymi spiskami groups i fields

=cut

sub create_childs {
    my ( $self, $filter, $replace ) = @_;
    #Sozdanie ob'ektov iz elementov massivov grupp i polei
    foreach my $key ( keys %$self ) {
        if ( grep{ $key eq $_ } $self->config->lists_of_containers ) {
            my $new = [];
            foreach my $group ( @{ $self->{$key} } ) {
                #Sozdaem ob'ekt
                $group = $self->create_child( $group, $filter, $replace );
                next if ( defined $group->{ $group->config->{filter} } and ( $filter & $group->{ $group->config->{filter} } ) != $filter );
                #Rekursivno vyzyvaem sebya na massive sozdannogo ob'ekta
                $group = $group->create_childs( $filter, $replace );
                push @$new, $group;
            }
            $self->{$key} = $new;
            #Poisk polya ot kotorogo zavisit tekuschee v ramkah massiva gruppy
            foreach my $group ( grep { $_->{ $_->config->{dependent} } or $_->{ $_->config->{dependent_on} } } @{ $self->{$key} } ) {
                ( $group->{$group->config->{dependent}} ) = grep { ref $_ and $_->{ $_->config->{formfield} } and $group->{$group->config->{dependent} } and $group->{$group->config->{dependent} } eq $_->{ $_->config->{formfield} } } @{ $self->{$key} } unless ref $group->{ $group->config->{dependent} };
                ( $group->{ $group->config->{dependent_on} } ) = grep { ref $_ and $_->{ $_->config->{formfield} } and $group->{ $group->config->{dependent_on} } and $group->{ $group->config->{dependent_on} } eq $_->{ $_->config->{formfield} } } @{ $self->{$key} } unless ref $group->{ $group->config->{dependent_on} };
            }
        }
    }
    $self->sort_by_order();
    return $self;
}

=head2 filter_fields

	Poisk edinstvennogo znacheniya v heshe fil'trov
	...
	$filter = 1
	...
	Vernet
	DEFAULT ispol'zuetsya dlya sluchaev, kogda znachenie ne naideno
	Esli znachenie ne naideno, pole udalyaetsya

=cut

sub filter_fields {
    my ($self, $filter) = @_;
    foreach my $key ( grep{$_ ne 'config'} keys %$self ) {
        if ( ref $self->{$key} eq 'HASH' ) {
            my $res;
            foreach my $k ( grep { $_ ne $self->config->{default_filter} } keys %{ $self->{$key} } ) {
                $res = $self->{$key}->{$k} if ( $filter & $k ) == $k;
            }
            $res ||= $self->{$key}->{ $self->config->{default_filter} };
            if ( $res ) {
                $self->{$key} = $res;
            } else {
                delete $self->{$key};
            }
        }
    }
    return $self;
}

=head2 sort_by_order

	Sortiruet massiv polei 'groups' i 'fields' v ob'ekte soglasno polyu 'order'

=cut

sub sort_by_order {
    my $self = shift;
    foreach my $field ( $self->config->lists_of_containers ) {
        if ( $self->{$field} and ref $self->{$field} eq 'ARRAY' ) {
            @{ $self->{$field} } = sort { defined $a->{ $self->config->{order} } and defined $b->{ $self->config->{order} } ? $a->{ $self->config->{order} } <=> $b->{ $self->config->{order} } : 0 } @{ $self->{ $field } };
        }
    }
    return $self;
}

=head2 get_subfield

	Vozvraschaet pervyi po spisku element iz polei potomkov s ukazannym imenem

=cut

sub get_subfield {
    my $self = shift;
    my $formfield = shift; #Znachenie polya
    ( $self->{_subfields}->{$formfield} ) = grep { $_->{$self->config->{formfield}} eq $formfield } @{ $self->get_field_list() } unless $self->{_subfields}->{$formfield};
    return $self->{_subfields}->{$formfield};
}

=head2 get_field_list

	List of fields

=cut

sub get_field_list {
    my $self = shift;
    return wantarray ? @{ $self->{ $self->config->{fields} } || [] } : ( $self->{ $self->config->{fields} } || [] );
}

=head2 all_dependent_on

	Vse zavisimye elementy dannogo konteinera

=cut

sub all_dependent_on {
    my $self = shift;
    my @res = ();
    my $dependent_on = defined $self->config->{dependent_on} ? $self->{ $self->config->{dependent_on} } : undef;
    push @res, $dependent_on->all_dependent_on() if ( ref $dependent_on );
    push @res, $self;
    return wantarray ? @res : \@res;
}

=head2 full_prefix

	Polnyi prefiks. Sostavlyaetsya iz prefiksa formy i prefiksov ob'ektov

=cut

sub full_prefix {
    my $self = shift;
    return ( $self->{ $self->config->{global_prefix} } || '' ) . ( $self->{ $self->config->{prefix} } || '' );
}

=head2 full_form_name

	Polnoe imya bez global'nogo prefiksa formy

=cut

sub full_form_name {
    my $self = shift;
    return ( $self->{$self->config->{prefix}} || '' ) . ( $self->{ $self->config->{formfield} } || '' );
}

=head2 global_form_name

	Imya polya v fore s uchetom global'nogo prefiksa

=cut

sub global_form_name {
    my $self = shift;
    $self->full_prefix() . $self->{ $self->config->{formfield} };
}

=head2 dependent_value_not_set

	Est' ob'ekt ot kotorogo zavisim, no u nego ne ustanovleno pole value

=cut

sub dependent_value_not_set {
    my $self = shift;
    my $key = shift;
    return 1 if defined $self->{ $self->config->{dependent} } and !$self->{ $self->config->{dependent} }->{$key};
    return 0;
}

=head2 is_dependent_to

	Proveryaet nalichie polya sredi dereva zavisimyh

=cut

sub is_dependent_to {
    my $self = shift;
    my $field = shift;
    return 1 if $self->global_form_name() eq $field;
    if ( $self->{ $self->config->{dependent} } ) {
        return $self->{ $self->config->{dependent} }->is_dependent_to( $field );
    }
    return 0;
}

=head1 AUTHOR

	shv, C<< <shv@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-form-declare-object at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Form-Declare-Object>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Form::Declare::Object


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Form-Declare-Object>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Form-Declare-Object>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Form-Declare-Object>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Form-Declare-Object>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 shv, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of HTML::Form::Declare::Object
