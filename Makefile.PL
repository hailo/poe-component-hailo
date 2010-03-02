use strict;
use warnings;
use utf8;
use 5.010;
use inc::Module::Install;

if ($inc::Module::Install::VERSION lt '0.94') {
    die 'Module::Install is too old';
}

name           ('POE-Component-Hailo');
perl_version   ('5.010');
author         ('Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>');
abstract_from  ('lib/POE/Component/Hailo.pm');
version_from   ('lib/POE/Component/Hailo.pm');
license        ('perl');
homepage       ('http://search.cpan.org/dist/POE-Component-Hailo');
githubmeta     ();
bugtracker     ('http://github.com/hinrik/poe-component-hailo/issues');
resources      (Ratings => 'http://cpanratings.perl.org/d/POE-Component-Hailo');

requires       ('Hailo' => '0.15');
requires       ('POE'   => '0');

tests_recursive();
test_requires  ('Test::More' => '0');

author_requires('Perl::Critic'        => '1.098');
author_requires('Test::Perl::Critic'  => '0');
author_requires('Test::Pod'           => '1.41');
author_requires('Test::Pod::Coverage' => '1.08');

WriteAll();
