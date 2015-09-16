VALAFLAGS =\
					 --vapidir ../ \
					 $(VALA_PACKAGES)

unit_test_server_CPPFLAGS = \
													$(LIBMODBUS_CFLAGS)

unit_test_server_LDADD = \
													$(LIBMODBUS_LIBS)

bin_PROGRAMS = \
							 unit_test_server

unit_test_server_SOURCES = \
													 unit-test-server.vala
