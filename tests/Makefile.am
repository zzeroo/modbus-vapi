VALAFLAGS =\
					 --vapidir ../ \
					 $(VALA_PACKAGES) \
					 $(VALA_DEBUG_FLAGS) \
					 $(NULL)

unit_test_server_CPPFLAGS = \
													$(LIBMODBUS_CFLAGS)

unit_test_server_LDADD = \
													$(LIBMODBUS_LIBS)

bin_PROGRAMS = \
							 unit-test-server

unit_test_server_SOURCES = \
													 unit-test-server.vala
