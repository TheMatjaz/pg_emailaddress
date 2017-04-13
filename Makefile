PG_CONFIG = pg_config
PKG_CONFIG = pkg-config

EXTENSION = pg_emailaddress
MODULE_big = pg_emailaddress
OBJS = pg_emailaddress.o
DATA = pg_emailaddress--0.0.0.sql

REGRESS = init test
REGRESS_OPTS = --inputdir=test

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
