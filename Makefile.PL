use 5.008008;
use inc::Module::Install;

name     'HTML-Form-Declare';
all_from 'lib/HTML/Form/Declare.pm';
author   'shv <shv@cpan.org>';

requires ( 'Data::Dumper' => 0, 'Carp' => 0 );

build_requires 'Test::More';

auto_install;

WriteAll;

