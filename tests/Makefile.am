VALAFLAGS =\
					 --vapidir ../ \
					 $(VALA_PACKAGES) \
					 $(VALA_DEBUG_FLAGS) \
					 $(NULL)

AM_CPPFLAGS = \
													$(LIBMODBUS_CFLAGS)

LDADD = \
													$(LIBMODBUS_LIBS)

noinst_PROGRAMS = \
							 unit-test-server \
							 unit-test-client

unit_test_server_SOURCES = \
													 unit-test-server.vala

unit_test_client_SOURCES = \
													 unit-test-client.vala

CLEANFILES = *~ *.log

noinst_SCRIPTS=unit-tests.sh
TESTS=./unit-tests.sh

