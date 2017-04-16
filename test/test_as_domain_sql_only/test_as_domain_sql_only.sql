-- The tests in this file are designed to return TRUE if they pass.
-- Run this file in psql with the --echo-queries flag to get it print the query
-- string to stdout before the query result so you see what passes and what does
-- not. Example:
-- psql --echo-queries --file=test_as_domain_sql_only.sql

\x off
\timing off
SET client_min_messages = warning;

-- Legal addresses. If legal, they can be an emailaddress data type.
SELECT seems_email_address('pg.sql@postgresql.org');
SELECT seems_email_address('PGsql@postgresql.org');
SELECT seems_email_address('  pgsq l@post gresql.or g ');
SELECT seems_email_address('"this is a valid address"@postgresql.org');
SELECT seems_email_address('"this is @lso v@lid"@postgresql.org');
SELECT seems_email_address('pgsql123@127.0.0.1');
SELECT seems_email_address('pgsql@localhost');
SELECT seems_email_address('pgsql@.');
SELECT seems_email_address(NULL) = TRUE;

-- Illegal addresses.
SELECT NOT seems_email_address('');
SELECT NOT seems_email_address('   ');
SELECT NOT seems_email_address('foo@');
SELECT NOT seems_email_address('@');
SELECT NOT seems_email_address('@bar');
SELECT NOT seems_email_address('foobar');

-- Cleaning text.
SELECT emailaddress_clean_text('a.bc@postgresql.org') = 'a.bc@postgresql.org'; 
SELECT emailaddress_clean_text('   abc@postgresql.org  ') = 'abc@postgresql.org'; 
SELECT emailaddress_clean_text('A.BC@POSTGRESQL.org') = 'a.bc@postgresql.org'; 
SELECT emailaddress_clean_text('   <abc@postgresql.org>  ') = 'abc@postgresql.org'; 
SELECT emailaddress_clean_text('<abc@postgresql.org>  ') = 'abc@postgresql.org'; 
SELECT emailaddress_clean_text(' <  abc@POSTGRESQL.org > ') = 'abc@postgresql.org'; 

-- Cleaning addresses.
SELECT emailaddress_clean('a.bc@postgresql.org') = 'a.bc@postgresql.org'; 
SELECT emailaddress_clean('   abc@postgresql.org  ') = 'abc@postgresql.org'; 
SELECT emailaddress_clean('A.BC@POSTGRESQL.org') = 'a.bc@postgresql.org'; 
SELECT emailaddress_clean('   <abc@postgresql.org>  ') = 'abc@postgresql.org'; 
SELECT emailaddress_clean('<abc@postgresql.org>  ') = 'abc@postgresql.org'; 
SELECT emailaddress_clean(' <  abc@POSTGRESQL.org > ') = 'abc@postgresql.org'; 

-- Cleaning addresses, removing periods.
SELECT emailaddress_clean_no_periods('a.bc@postgresql.org') = 'abc@postgresql.org'; 
SELECT emailaddress_clean_no_periods('   abc@postgresql.org  ') = 'abc@postgresql.org'; 
SELECT emailaddress_clean_no_periods('A.BC@POSTGRESQL.org') = 'abc@postgresql.org'; 
SELECT emailaddress_clean_no_periods('   <abc@postgresql.org>  ') = 'abc@postgresql.org'; 
SELECT emailaddress_clean_no_periods('<abc@postgresql.org>  ') = 'abc@postgresql.org'; 
SELECT emailaddress_clean_no_periods(' <  abc@POSTGRESQL.org > ') = 'abc@postgresql.org'; 

-- Building addresses.
SELECT emailaddress_build('USERNAME', 'hostname.com') = 'username@hostname.com';
SELECT emailaddress_build('USER.NAME', 'hostname.com') = 'user.name@hostname.com';
SELECT emailaddress_build('  username ', '  hostname.com  ') = 'username@hostname.com';
SELECT emailaddress_build('  user.name ', '  hostname.com  ') = 'user.name@hostname.com';
SELECT emailaddress_build(NULL, 'hostname.com') IS NULL;
SELECT emailaddress_build('username', NULL) IS NULL;
SELECT emailaddress_build(NULL, NULL) IS NULL;

-- Building addresses, separate TLD.
SELECT emailaddress_build('username', 'hostname', 'COM') = 'username@hostname.com';
SELECT emailaddress_build('user.name', 'hostname', 'COM') = 'user.name@hostname.com';
SELECT emailaddress_build('  username  ', ' hostname ', ' com ') = 'username@hostname.com';
SELECT emailaddress_build('  user.name  ', ' hostname ', ' com ') = 'user.name@hostname.com';
SELECT emailaddress_build(NULL, 'hostname', 'com') IS NULL;
SELECT emailaddress_build(NULL, NULL, 'com') IS NULL;
SELECT emailaddress_build('username', NULL, NULL) IS NULL;
SELECT emailaddress_build(NULL, NULL, NULL) IS NULL;

-- Building addresses, removing periods.
SELECT emailaddress_build_no_periods('USERNAME', 'hostname.com') = 'username@hostname.com';
SELECT emailaddress_build_no_periods('USER.NAME', 'hostname.com') = 'username@hostname.com';
SELECT emailaddress_build_no_periods('  username ', '  hostname.com  ') = 'username@hostname.com';
SELECT emailaddress_build_no_periods('  user.name ', '  hostname.com  ') = 'username@hostname.com';
SELECT emailaddress_build_no_periods(NULL, 'hostname.com') IS NULL;
SELECT emailaddress_build_no_periods('username', NULL) IS NULL;
SELECT emailaddress_build_no_periods(NULL, NULL) IS NULL;

-- Building addresses, removing periods, separate TLD.
SELECT emailaddress_build_no_periods('username', 'hostname', 'COM') = 'username@hostname.com';
SELECT emailaddress_build_no_periods('user.name', 'hostname', 'COM') = 'username@hostname.com';
SELECT emailaddress_build_no_periods('  username  ', ' hostname ', ' com ') = 'username@hostname.com';
SELECT emailaddress_build_no_periods('  user.name  ', ' hostname ', ' com ') = 'username@hostname.com';
SELECT emailaddress_build_no_periods(NULL, 'hostname', 'com') IS NULL;
SELECT emailaddress_build_no_periods(NULL, NULL, 'com') IS NULL;
SELECT emailaddress_build_no_periods('username', NULL, NULL) IS NULL;
SELECT emailaddress_build_no_periods(NULL, NULL, NULL) IS NULL;

-- Adding brackets, includes cleaning.
SELECT emailaddress_add_brackets('abc@postgresql.org') = '<abc@postgresql.org>'; 
SELECT emailaddress_add_brackets('   abc@postgresql.org  ') = '<abc@postgresql.org>'; 
SELECT emailaddress_add_brackets('ABC@POSTGRESQL.org') = '<abc@postgresql.org>'; 
SELECT emailaddress_add_brackets('   <abc@postgresql.org>  ') = '<abc@postgresql.org>'; 
SELECT emailaddress_add_brackets('<abc@postgresql.org>  ') = '<abc@postgresql.org>'; 
SELECT emailaddress_add_brackets(' <  abc@POSTGRESQL.org > ') = '<abc@postgresql.org>'; 

-- Hostname extraction.
SELECT emailaddress_get_hostname('pg.sql@postgresql.org') = 'postgresql.org';
SELECT emailaddress_get_hostname('PGSQL@postgresql.org') = 'postgresql.org';
SELECT emailaddress_get_hostname('  pgsq l@post gresql.or g ') = 'post gresql.or g';
SELECT emailaddress_get_hostname('"this is a valid address"@postgresql.org') = 'postgresql.org';
SELECT emailaddress_get_hostname('"this is @lso v@lid"@postgresql.org') = 'postgresql.org';
SELECT emailaddress_get_hostname('pgsql123@127.0.0.1') = '127.0.0.1';
SELECT emailaddress_get_hostname('pgsql@localhost') = 'localhost';
SELECT emailaddress_get_hostname('pgsql@.') = '.';
SELECT emailaddress_get_hostname(NULL) IS NULL;

-- Username extraction.
SELECT emailaddress_get_username('pg.sql@postgresql.org') = 'pg.sql';
SELECT emailaddress_get_username('PGSQL@postgresql.org') = 'pgsql';
SELECT emailaddress_get_username('  pgsq l@post gresql.or g ') = 'pgsq l';
SELECT emailaddress_get_username('"this is a valid address"@postgresql.org') = '"this is a valid address"';
SELECT emailaddress_get_username('"this is @lso v@lid"@postgresql.org') = '"this is @lso v@lid"';
SELECT emailaddress_get_username('pgsql123@127.0.0.1') = 'pgsql123';
SELECT emailaddress_get_username('pgsql@localhost') = 'pgsql';
SELECT emailaddress_get_username(NULL) IS NULL;

-- Username extraction, without periods.
SELECT emailaddress_get_username_no_periods('pg.sql@postgresql.org') = 'pgsql';
SELECT emailaddress_get_username_no_periods('PGSQL@postgresql.org') = 'pgsql';
SELECT emailaddress_get_username_no_periods('  pgsq l@post gresql.or g ') = 'pgsq l';
SELECT emailaddress_get_username_no_periods('"this is a valid address"@postgresql.org') = '"this is a valid address"';
SELECT emailaddress_get_username_no_periods('"this is @lso v@lid"@postgresql.org') = '"this is @lso v@lid"';
SELECT emailaddress_get_username_no_periods('pgsql123@127.0.0.1') = 'pgsql123';
SELECT emailaddress_get_username_no_periods('pgsql@localhost') = 'pgsql';
SELECT emailaddress_get_username_no_periods(NULL) IS NULL;

-- Hostname modification.
SELECT emailaddress_set_hostname('pg.sql@postgresql.org', 'z.org') = 'pg.sql@z.org';
SELECT emailaddress_set_hostname('PGSQL@postgresql.org', 'Z.ORG') = 'pgsql@z.org';
SELECT emailaddress_set_hostname('  pgsq l@post gresql.or g ', 'z.org') = 'pgsq l@z.org';
SELECT emailaddress_set_hostname('"this is a valid address"@postgresql.org', 'z.org') = '"this is a valid address"@z.org';
SELECT emailaddress_set_hostname('"this is @lso v@lid"@postgresql.org', 'z.org') = '"this is @lso v@lid"@z.org';
SELECT emailaddress_set_hostname('pgsql123@127.0.0.1', 'z.org') = 'pgsql123@z.org';
SELECT emailaddress_set_hostname('pgsql@localhost', 'z.org') = 'pgsql@z.org';
SELECT emailaddress_set_hostname(NULL, 'z.org') IS NULL;
SELECT emailaddress_set_hostname('a@postgresql.org', NULL) IS NULL;
SELECT emailaddress_set_hostname(NULL, NULL) IS NULL;

-- Username modification.
SELECT emailaddress_set_username('x', 'pg.sql@postgresql.org') = 'x@postgresql.org';
SELECT emailaddress_set_username('X', 'PGSQL@postgresql.org') = 'x@postgresql.org';
SELECT emailaddress_set_username('x', '  pgsq l@post gresql.or g ') = 'x@post gresql.or g';
SELECT emailaddress_set_username('x', '"this is a valid address"@postgresql.org') = 'x@postgresql.org';
SELECT emailaddress_set_username('x', '"this is @lso v@lid"@postgresql.org') = 'x@postgresql.org';
SELECT emailaddress_set_username('x', 'pgsql123@127.0.0.1') = 'x@127.0.0.1';
SELECT emailaddress_set_username('x', 'pgsql@localhost') = 'x@localhost';
SELECT emailaddress_set_username(NULL, 'pgsql@localhost') IS NULL;
SELECT emailaddress_set_username('x', NULL) IS NULL;
SELECT emailaddress_set_username(NULL, NULL) IS NULL;

-- Username modification, without periods.
SELECT emailaddress_set_username_no_periods('x.y', 'pg.sql@postgresql.org') = 'xy@postgresql.org';
SELECT emailaddress_set_username_no_periods('X.Y', 'PGSQL@postgresql.org') = 'xy@postgresql.org';
SELECT emailaddress_set_username_no_periods('x.y', '  pgsq l@post gresql.or g ') = 'xy@post gresql.or g';
SELECT emailaddress_set_username_no_periods('x.y', '"this is a valid address"@postgresql.org') = 'xy@postgresql.org';
SELECT emailaddress_set_username_no_periods('x.y', '"this is @lso v@lid"@postgresql.org') = 'xy@postgresql.org';
SELECT emailaddress_set_username_no_periods('x.y', 'pgsql123@127.0.0.1') = 'xy@127.0.0.1';
SELECT emailaddress_set_username_no_periods('x.y', 'pgsql@localhost') = 'xy@localhost';
SELECT emailaddress_set_username(NULL, 'pgsql@localhost') IS NULL;
SELECT emailaddress_set_username_no_periods('x.y', NULL) IS NULL;
SELECT emailaddress_set_username(NULL, NULL) IS NULL;

-- Comparison operators, which include the comparison functions.
SELECT     'abc@postgresql.org'::emailaddress = 'abc@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress = 'FFF@postgresql.org'::emailaddress;

SELECT     'abc@postgresql.org'::emailaddress <> 'aaa@postgresql.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress != 'aaa@postgresql.org'::emailaddress;

SELECT (NULL::emailaddress = 'aaa@postgresql.org'::emailaddress) IS NULL;
SELECT (NULL::emailaddress <> 'aaa@postgresql.org'::emailaddress) IS NULL;

SELECT     'abc@postgresql.org'::emailaddress < 'abd@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress < 'abc@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress < 'aaa@postgresql.org'::emailaddress;
SELECT NOT 'abc@z.org'::emailaddress < 'aaa@postgresql.org'::emailaddress;
SELECT     '123@postgresql.org'::emailaddress < 'aaa@postgresql.org'::emailaddress;

SELECT     'abc@postgresql.org'::emailaddress =< 'abd@postgresql.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress =< 'abc@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress =< 'aaa@postgresql.org'::emailaddress;

SELECT NOT 'abc@postgresql.org'::emailaddress > 'z@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress > 'abc@postgresql.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress > 'aaa@postgresql.org'::emailaddress;
SELECT     'abc@z.org'::emailaddress > 'aaa@postgresql.org'::emailaddress;

SELECT     'abc@postgresql.org'::emailaddress = 'abc@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress = 'abd@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress = 'abd@p.org'::emailaddress;

SELECT     'abc@postgresql.org'::emailaddress @= 'z@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress @= 'z@abc.org'::emailaddress;

SELECT NOT 'abc@postgresql.org'::emailaddress @<> 'z@postgresql.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress @<> 'z@abc.org'::emailaddress;

SELECT     'abc@postgresql.org'::emailaddress =@ 'abc@z.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress =@ 'abc@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress =@ 'z@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress =@ 'z@z.org'::emailaddress;

SELECT NOT 'abc@postgresql.org'::emailaddress <>@ 'abc@z.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress <>@ 'abc@postgresql.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress <>@ 'z@postgresql.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress <>@ 'z@z.org'::emailaddress;

SELECT     'a.bc@postgresql.org'::emailaddress ~=@ 'a.bc@postgresql.org'::emailaddress;
SELECT     'a.bc@postgresql.org'::emailaddress ~=@ 'abc@postgresql.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress ~=@ 'ab.c@postgresql.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress ~=@ 'abc@postgresql.org'::emailaddress;
SELECT NOT 'a.bc@postgresql.org'::emailaddress ~=@ 'z.@postgresql.org'::emailaddress;
SELECT NOT 'a.bc@postgresql.org'::emailaddress ~=@ 'z@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress ~=@ 'z.@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress ~=@ 'z@postgresql.org'::emailaddress;
SELECT NOT 'a.bc@postgresql.org'::emailaddress ~=@ 'z@z.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress ~=@ 'z.@z.org'::emailaddress;
SELECT NOT 'a.bc@postgresql.org'::emailaddress ~=@ 'z.@z.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress ~=@ 'z@z.org'::emailaddress;

SELECT NOT 'a.bc@postgresql.org'::emailaddress ~<>@ 'abc@z.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress ~<>@ 'a.bc@z.org'::emailaddress;
SELECT NOT 'a.bc@postgresql.org'::emailaddress ~<>@ 'a.bc@z.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress ~<>@ 'abc@z.org'::emailaddress;
SELECT NOT 'a.bc@postgresql.org'::emailaddress ~<>@ 'abc@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress ~<>@ 'a.bc@postgresql.org'::emailaddress;
SELECT NOT 'a.bc@postgresql.org'::emailaddress ~<>@ 'a.bc@postgresql.org'::emailaddress;
SELECT NOT 'abc@postgresql.org'::emailaddress ~<>@ 'abc@postgresql.org'::emailaddress;
SELECT     'a.bc@postgresql.org'::emailaddress ~<>@ 'z@postgresql.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress ~<>@ 'z.@postgresql.org'::emailaddress;
SELECT     'a.bc@postgresql.org'::emailaddress ~<>@ 'z.@postgresql.org'::emailaddress;
SELECT     'a.bc@postgresql.org'::emailaddress ~<>@ 'z@postgresql.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress ~<>@ 'z.@z.org'::emailaddress;
SELECT     'a.bc@postgresql.org'::emailaddress ~<>@ 'z.@z.org'::emailaddress;
SELECT     'abc@postgresql.org'::emailaddress ~<>@ 'z@z.org'::emailaddress;

-- Comparison function used for B-Tree indexing.
SELECT emailaddress_compare('aaa@postgresql.org', 'aaa@postgresql.org') = 0;
SELECT emailaddress_compare('aaa@postgresql.org', 'zzz@postgresql.org') = -1;
SELECT emailaddress_compare('zzz@postgresql.org', 'aaa@postgresql.org') = 1;

SELECT emailaddress_compare('aaa@a.org', 'aaa@z.org') = -1;
SELECT emailaddress_compare('aaa@z.org', 'aaa@a.org') = 1;

SELECT emailaddress_compare('zzz@a.org', 'aaa@z.org') = -1;
SELECT emailaddress_compare('aaa@z.org', 'zzz@a.org') = 1;


-- Sorting.
CREATE TEMPORARY TABLE emailaddress_sorting_test (
       expected_position integer,
       email_address     emailaddress
);
INSERT INTO emailaddress_sorting_test
       (expected_position, email_address)
VALUES (9, 'pg.sql@postgresql.org'),
       (10,'pgsql@postgresql.org'),
       (8, '"this is a valid address"@postgresql.org'),
       (7, '"this is @lso v@lid"@postgresql.org'),
       (2, 'pgsql123@127.0.0.1'),
       (6, 'pgsql@localhost'),
       (5, 'azz@localhost'),
       (3, 'aaa@localhost'),
       (4, 'abc@localhost'),
       (1, 'pgsql@.');
SELECT expected_position, email_address
  FROM emailaddress_sorting_test
 ORDER BY @* email_address, *@ email_address ASC;