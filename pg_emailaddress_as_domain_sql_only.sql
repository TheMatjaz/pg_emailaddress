-- Complain if script is sourced in psql, rather than via CREATE EXTENSION
-- \echo Use "CREATE EXTENSION pg_emailaddress;" to load this file. \quit

BEGIN TRANSACTION;

CREATE OR REPLACE FUNCTION seems_email_address
    (email_address text)
    RETURNS boolean
    CALLED ON NULL INPUT
    IMMUTABLE
    SECURITY INVOKER
    LANGUAGE sql
    LEAKPROOF
    AS $body$
        SELECT email_address IS NULL
               OR email_address ~ '[ -~]+@[ -~]+';
    $body$;

COMMENT ON FUNCTION seems_email_address(text) IS
'Checks whether a string could be an legal e-mail address.

It''s very hard to define legal e-mail addresses according to the RFC so this 
function uses a minimalistic approach:

- returns TRUE when the string is NULL, because NULL may be a legal e-mail 
  address which is currently unknown
- returns TRUE if the string contains at least 3 characters, one of them 
  is the `@` symbol and all characters are ASCII printable characters
- returns FALSE otherwise.';

  DROP DOMAIN IF EXISTS emailaddress CASCADE;
CREATE DOMAIN emailaddress
       AS text
       -- COLLATE ???
       DEFAULT NULL
       CONSTRAINT legal_email_address_format
            CHECK (seems_email_address(VALUE));

COMMENT ON DOMAIN emailaddress IS
'String containing an e-mail address.

Defaults to NULL, uses a C collate and performs a minimal check of the content.
Be aware that any string matching the seems_email_address(text) function can be
part of this domain.';

CREATE OR REPLACE FUNCTION emailaddress_get_username
    (email_address emailaddress)
    RETURNS text
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT lower(trim(substring(email_address FROM '^(.+)@')));
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_get_username_no_periods
    (email_address emailaddress)
    RETURNS text
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT lower(trim(substring(replace(email_address, '.', '')
                                            FROM '^(.+)@')));
    $body$;
    -- Returns the substring up to the last @ symbol filtering the

CREATE OR REPLACE FUNCTION emailaddress_get_hostname
    (email_address emailaddress)
    RETURNS text
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT lower(trim(substring(email_address FROM '[^@]+$')));
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_set_username
    (new_username text, email_address emailaddress)
    RETURNS emailaddress
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT (lower(trim(new_username))
               || '@' 
               || emailaddress_get_hostname(email_address)) :: emailaddress;
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_set_username_no_periods
    (new_username text, email_address emailaddress)
    RETURNS emailaddress
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT (lower(replace(trim(new_username), '.', ''))
               || '@'
               || emailaddress_get_hostname(email_address)) :: emailaddress;
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_set_hostname
    (email_address emailaddress, new_hostname text)
    RETURNS emailaddress
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT (emailaddress_get_username(email_address)
               || '@' 
               || lower(trim(new_hostname))) :: emailaddress;
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_build
    (username text, hostname_with_tld text)
    RETURNS emailaddress
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT lower(trim(username)
               || '@' 
               || trim(hostname_with_tld)) :: emailaddress;
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_build
    (username text, hostname_without_tld text, tld text)
    RETURNS emailaddress
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT lower(trim(username) 
                     || '@'
                     || trim(hostname_without_tld)
                     || '.'
                     || trim(tld)) :: emailaddress;
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_envelope
    (email_address emailaddress)
    RETURNS text
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT '<' || lower(trim(email_address)) || '>';
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_trim_envelope
    (email_address_with_envelope text)
    RETURNS emailaddress
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT lower(trim('<>' FROM email_address_with_envelope))
               :: emailaddress;
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_gt
    (one emailaddress, two emailaddress)
    RETURNS boolean
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT emailaddress_get_hostname(one) 
               > emailaddress_get_hostname(two)
               OR (emailaddress_get_hostname(one) 
                  = emailaddress_get_hostname(two)
                  AND emailaddress_get_username(one) 
                      > emailaddress_get_username(two));
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_ge
    (one emailaddress, two emailaddress)
    RETURNS boolean
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT emailaddress_get_hostname(one) 
               > emailaddress_get_hostname(two)
               OR (emailaddress_get_hostname(one) 
                  = emailaddress_get_hostname(two)
                  AND emailaddress_get_username(one) 
                      >= emailaddress_get_username(two));
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_lt
    (one emailaddress, two emailaddress)
    RETURNS boolean
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT emailaddress_get_hostname(one) 
               < emailaddress_get_hostname(two)
               OR (emailaddress_get_hostname(one) 
                  = emailaddress_get_hostname(two)
                  AND emailaddress_get_username(one) 
                      < emailaddress_get_username(two));
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_le
    (one emailaddress, two emailaddress)
    RETURNS boolean
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT emailaddress_get_hostname(one) 
               < emailaddress_get_hostname(two)
               OR (emailaddress_get_hostname(one) 
                  = emailaddress_get_hostname(two)
                  AND emailaddress_get_username(one) 
                      <= emailaddress_get_username(two));
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_eq_hostname
    (one emailaddress, two emailaddress)
    RETURNS boolean
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT emailaddress_get_hostname(one)
               = emailaddress_get_hostname(two);
    $body$;


CREATE OR REPLACE FUNCTION emailaddress_ne_hostname
    (one emailaddress, two emailaddress)
    RETURNS boolean
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT emailaddress_get_hostname(one)
               <> emailaddress_get_hostname(two);
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_eq_username
    (one emailaddress, two emailaddress)
    RETURNS boolean
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT emailaddress_get_username(one)
               = emailaddress_get_username(two);
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_ne_username
    (one emailaddress, two emailaddress)
    RETURNS boolean
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT emailaddress_get_username(one)
               <> emailaddress_get_username(two);
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_eq_username_no_periods
    (one emailaddress, two emailaddress)
    RETURNS boolean
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT emailaddress_get_username_no_periods(one)
               = emailaddress_get_username_no_periods(two);
    $body$;

CREATE OR REPLACE FUNCTION emailaddress_ne_username_no_periods
    (one emailaddress, two emailaddress)
    RETURNS boolean
    RETURNS NULL ON NULL INPUT
    IMMUTABLE
    LANGUAGE sql
    AS $body$
        SELECT emailaddress_get_username_no_periods(one)
               <> emailaddress_get_username_no_periods(two);
    $body$;

CREATE OPERATOR @* (
    RIGHTARG   = emailaddress,
    PROCEDURE  = emailaddress_get_hostname
);

CREATE OPERATOR *@ (
    RIGHTARG   = emailaddress,
    PROCEDURE  = emailaddress_get_username
);

CREATE OPERATOR ~*@ (
    RIGHTARG   = emailaddress,
    PROCEDURE  = emailaddress_get_username_no_periods
);

CREATE OPERATOR < (
    LEFTARG = emailaddress,
    RIGHTARG = emailaddress,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel,
    PROCEDURE = emailaddress_lt
);

CREATE OPERATOR =< (
    LEFTARG = emailaddress,
    RIGHTARG = emailaddress,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel,
    PROCEDURE = emailaddress_le
);

CREATE OPERATOR >= (
    LEFTARG = emailaddress,
    RIGHTARG = emailaddress,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel,
    PROCEDURE = emailaddress_ge
);

CREATE OPERATOR > (
    LEFTARG = emailaddress,
    RIGHTARG = emailaddress,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel,
    PROCEDURE = emailaddress_gt
);

CREATE OPERATOR @= (
    LEFTARG = emailaddress,
    RIGHTARG = emailaddress,
    COMMUTATOR = @=,
    NEGATOR = @<>,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel,
    PROCEDURE = emailaddress_eq_hostname
);

CREATE OPERATOR @<> (
    LEFTARG = emailaddress,
    RIGHTARG = emailaddress,
    COMMUTATOR = @<>,
    NEGATOR = @=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel,
    PROCEDURE = emailaddress_ne_hostname
);

CREATE OPERATOR =@ (
    LEFTARG = emailaddress,
    RIGHTARG = emailaddress,
    COMMUTATOR = =@,
    NEGATOR = <>@,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel,
    PROCEDURE = emailaddress_eq_username
);

CREATE OPERATOR <>@ (
    LEFTARG = emailaddress,
    RIGHTARG = emailaddress,
    COMMUTATOR = <>@,
    NEGATOR = =@,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel,
    PROCEDURE = emailaddress_ne_username
);

CREATE OPERATOR ~=@ (
    LEFTARG = emailaddress,
    RIGHTARG = emailaddress,
    COMMUTATOR = ~=@,
    NEGATOR = ~<>@,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel,
    PROCEDURE = emailaddress_eq_username_no_periods
);

CREATE OPERATOR ~<>@ (
    LEFTARG = emailaddress,
    RIGHTARG = emailaddress,
    COMMUTATOR = ~<>@,
    NEGATOR = ~=@,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel,
    PROCEDURE = emailaddress_ne_username_no_periods
);

-- CREATE OPERATOR CLASS emailaddress_ops
--        DEFAULT FOR TYPE emailaddress
--        USING btree AS
--        OPERATOR 1 <  ,
--        OPERATOR 2 <= ,
--        OPERATOR 3 =  ,
--        OPERATOR 4 >= ,
--        OPERATOR 5 >  ,
--        FUNCTION 1 emailaddress_eq(emailaddress, emailaddress);

COMMIT;
