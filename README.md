E-mail address datatype estension for PostgreSQL
================================================

https://twitter.com/pvh/status/667106073199775744

This is an extension for PostgreSQL that provides a type `emailaddress`
for storing and manipulating e-mail addresses.


Installation
------------

To build and install this module:

    make
    make install

or selecting a specific PostgreSQL installation:

    make PG_CONFIG=/some/where/bin/pg_config
    make PG_CONFIG=/some/where/bin/pg_config install


And finally inside the database:

    CREATE EXTENSION pg_emailaddress;


Using
-----

This module provides a data type `emailaddress` that you can use like a
normal type.  For example:

```sql
CREATE TABLE accounts (
    id int PRIMARY KEY,
    name text,
    email emailaddress
);

INSERT INTO accounts VALUES (1, 'Peter Eisentraut', 'peter@eisentraut.org');
```

The accepted addresses correspond approximately to the `addr-spec`
production in [RFC 5322](https://www.rfc-editor.org/rfc/rfc5322.txt)
(so it's of the type `foo@bar.com`, but not `"Some Name"
<foo@bar.com>`).


Request for feedback
--------------------

Let me now what other functionality you wish to see in an email
address type.
