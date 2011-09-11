use inc::Module::Install;
name 'WWW-BOOKSCAN';
all_from 'lib/WWW/BOOKSCAN.pm';
readme_from 'lib/WWW/BOOKSCAN.pm';

# requires '';
requires "Class::Accessor";
requires "Class::Singleton";
requires "HTML::SimpleLinkExtor";
requires "Hash::MoreUtils";
requires "LWP::UserAgent";
requires "List::MoreUtils";
requires "List::Util";
requires "Path::Class";
requires "Readonly";
requires "URI";
requires "URI::QueryParam";
requires "Web::Query";
requires "LWP::Protocol::https";

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;

