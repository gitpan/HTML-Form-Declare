use inc::Module::Install;

name     'HTML-Form-Declare';
all_from 'lib/HTML/Form/Declare.pm';
author   'shv <shv@cpan.org>';

build_requires 'Test::More';

auto_install;

WriteAll;

