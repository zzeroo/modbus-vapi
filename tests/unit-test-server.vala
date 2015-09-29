using Modbus;

class UnitTestServer : GLib.Object {

  /* Server allocates address + nb (number of bits) */
  private const uint16 UT_BITS_ADDRESS = 0x130;
  private const uint16 UT_BITS_NB = 0x25;
  private const uint8[] UT_BITS_TAB = { 0xCD, 0x6B, 0xB2, 0x0E, 0x1B };

  private const uint16 UT_INPUT_BITS_ADDRESS = 0x1C4;
  private const uint16 UT_INPUT_BITS_NB = 0x16;
  private const uint8[] UT_INPUT_BITS_TAB = { 0xAC, 0xDB, 0x35 };

  private const uint16 UT_REGISTERS_ADDRESS = 0x16B;
  /* Raise a manual exception when this address is used for the first byte */
  private const uint16 UT_REGISTERS_ADDRESS_SPECIAL = 0x6C;
  /* The response of the server will contains an invalid TID or slave */
  private const uint16 UT_REGISTERS_ADDRESS_INVALID_TID_OR_SLAVE = 0x6D;
  /* The server will wait for 1 second before replying to test timeout */
  private const uint16 UT_REGISTERS_ADDRESS_SLEEP_500_MS = 0x6E;
  /* The server will wait for 5 ms before sending each byte */
  private const uint16 UT_REGISTERS_ADDRESS_BYTE_SLEEP_5_MS = 0x6F;

  private const uint16 UT_REGISTERS_NB = 0x3;
  private const uint16[] UT_REGISTERS_TAB = { 0x022B, 0x0001, 0x0064 };
  /* If the following value is used, a bad response is sent.
     It's better to test with a lower value than
     REGISTERS_NB_POINTS to try to raise a segfault. */
  private const uint16 UT_REGISTERS_NB_SPECIAL = 0x2;

  private const uint16 UT_INPUT_REGISTERS_ADDRESS = 0x108;
  private const uint16 UT_INPUT_REGISTERS_NB = 0x1;
  private const uint16[] UT_INPUT_REGISTERS_TAB = { 0x000A };

  private const double UT_REAL = 916.540649;
  private const uint64 UT_IREAL = 0x4465229a;
  private const uint64 UT_IREAL_DCBA = 0x9a226544;

  private const uint8 SERVER_ID = 17;
  private const uint8 INVALID_SERVER_ID = 18;

/* For MinGW */
//#ifndef MSG_NOSIGNAL
  private const int MSG_NOSIGNAL = 0;
//#endif

  private int socket = -1; // Socket for modbus context
  private Context ctx;
  private Mapping modbus_mapping;
  private int return_code;
  private int i; // for loop counter
  private int use_backend;
  private uint8 *query;
  private int header_length;

  enum Mode {
    TCP,
    TCP_PI,
    RTU
  }

  public UnitTestServer () {
  }

  public UnitTestServer.rtu () {
  }

  ~UnitTestServer () {
    ctx.close ();
  }

  public int run (string[]? argv) {
    switch (argv[1]) {
      case "tcp":
        use_backend = Mode.TCP;
        break;
      case "tcppi":
        use_backend = Mode.TCP_PI;
        break;
      case "rtu":
        use_backend = Mode.RTU;
        break;
      default:
        /* By default */
        use_backend = Mode.TCP;
        break;
    }
    if (argv.length > 2) {
      stdout.printf ("Usage:\n  %s [tcp|tcppi|rtu] - Modbus server for unit testing\n\n", argv[0]);
      return -1;
    }

    if (use_backend == Mode.TCP) {
      ctx = new Context.tcp ("127.0.0.1", 1502);
      query = GLib.malloc (TcpAttributes.MAX_ADU_LENGTH);
    } else if (use_backend == Mode.TCP_PI) {
      ctx = new Context.tcp_pi ("::0", "1502");
      query = GLib.malloc (TcpAttributes.MAX_ADU_LENGTH);
    } else {
      ctx = new Context.rtu ("/dev/ttyUSB0", 115200, 'N', 8, 1);
      ctx.set_slave (SERVER_ID);
      query = GLib.malloc (RTU_MAX_ADU_LENGTH);
    }
    header_length = ctx.get_header_length ();

    ctx.set_debug (1);

    modbus_mapping = new Mapping (
        UT_BITS_ADDRESS + UT_BITS_NB,
        UT_INPUT_BITS_ADDRESS + UT_INPUT_BITS_NB,
        UT_REGISTERS_ADDRESS + UT_REGISTERS_NB,
        UT_INPUT_REGISTERS_ADDRESS + UT_INPUT_REGISTERS_NB);
    if (modbus_mapping == null) {
      error ("Failed to allocate the mapping: %s",
             Modbus.strerror(errno));
    }
    /* Unit tests of modbus_mapping_new (tests would not be sufficient if two
       nb_* were identical) */
    if (modbus_mapping.nb_bits != UT_BITS_ADDRESS + UT_BITS_NB) {
      error ("Invalid nb bits (%d != %d)", UT_BITS_ADDRESS + UT_BITS_NB,
             modbus_mapping.nb_bits);
    }

    if (modbus_mapping.nb_input_bits != UT_INPUT_BITS_ADDRESS + UT_INPUT_BITS_NB) {
      error ("Invalid nb input bits: %d\n", UT_INPUT_BITS_ADDRESS + UT_INPUT_BITS_NB);
    }

    if (modbus_mapping.nb_registers != UT_REGISTERS_ADDRESS + UT_REGISTERS_NB) {
      error ("Invalid nb registers: %d\n", UT_REGISTERS_ADDRESS + UT_REGISTERS_NB);
    }

    if (modbus_mapping.nb_input_registers != UT_INPUT_REGISTERS_ADDRESS + UT_INPUT_REGISTERS_NB) {
      error ("Invalid nb input registers: %d\n", UT_INPUT_REGISTERS_ADDRESS + UT_INPUT_REGISTERS_NB);
    }

    /* Examples from PI_MODBUS_300.pdf.
       Only the read-only input values are assigned. */

    /** INPUT STATUS **/
    set_bits_from_bytes(modbus_mapping.tab_input_bits,
                        UT_INPUT_BITS_ADDRESS, UT_INPUT_BITS_NB,
                        UT_INPUT_BITS_TAB);

    /** INPUT REGISTERS **/
    for (i = 0; i < UT_INPUT_REGISTERS_NB; i++) {
      modbus_mapping.tab_input_registers[UT_INPUT_REGISTERS_ADDRESS + i] =
          UT_INPUT_REGISTERS_TAB[i];
    }

    if (use_backend == Mode.TCP) {
        socket = ctx.tcp_listen(1);
        ctx.tcp_accept(&socket);
    } else if (use_backend == Mode.TCP_PI) {
        socket = ctx.tcp_pi_listen(1);
        ctx.tcp_pi_accept(&socket);
    } else {
        return_code = ctx.connect();
        if (return_code == -1) {
            stderr.printf("Unable to connect %s\n", Modbus.strerror(errno));
            return -1;
        }
    }

    for (;;) {
      do {
        return_code = ctx.receive(query);
        /* Filtered queries return 0 */
      } while (return_code == 0);

        /* The connection is not closed on errors which require on reply such as
           bad CRC in RTU. */
      if (return_code == -1 && errno != EMBBADCRC) {
        /* Quit */
        break;
      }

      /* Special server behavior to test the client */
      if (query[header_length] == 0x03) {
        /* Read holding registers */

        if (Get.int16_from_int8 (query, header_length + 3) ==
            UT_REGISTERS_NB_SPECIAL) {
          stdout.printf("Set an incorrect number of values\n");
          Set.int16_to_int8 (query, header_length + 3,
                             UT_REGISTERS_NB_SPECIAL - 1);
        } else if (Get.int16_from_int8 (query, header_length + 1)
                   == UT_REGISTERS_ADDRESS_SPECIAL) {
          stdout.printf("Reply to this special register address by an exception\n");
          ctx.reply_exception(query,
                              ModbusException.SLAVE_OR_SERVER_BUSY);
          continue;
        } else if (Get.int16_from_int8 (query, header_length + 1)
                   == UT_REGISTERS_ADDRESS_INVALID_TID_OR_SLAVE) {
          const int RAW_REQ_LENGTH = 5;
          uint8[] raw_req = {
            (use_backend == Mode.RTU) ? INVALID_SERVER_ID : 0xFF,
            0x03,
            0x02, 0x00, 0x00
          };

          stdout.printf("Reply with an invalid TID or slave\n");
          ctx.send_raw_request(raw_req, RAW_REQ_LENGTH * sizeof(uint8));
          continue;
        } else if (Get.int16_from_int8 (query, header_length +1)
                   == UT_REGISTERS_ADDRESS_SLEEP_500_MS) {
          stdout.printf("Sleep 0.5 s before replying\n");
          Posix.usleep(500000);
        } else if (Get.int16_from_int8 (query, header_length + 1)
                   == UT_REGISTERS_ADDRESS_BYTE_SLEEP_5_MS) {
          /* Test low level only available in TCP mode */
          /* Catch the reply and send reply byte a byte */
          uint8 req[] = {0x00, 0x1C, 0x00, 0x00, 0x00, 0x05, 0xFF, 0x03, 0x02,
            0x00, 0x00};

          int req_length = 11;
          int w_s = ctx.get_socket();

          /* Copy TID */
          req[1] = query[1];
          for (i=0; i < req_length; i++) {
            stdout.printf("(%.2X)", req[i]);
            Posix.usleep(5000);
            //FIXME: Ugly cast
            Posix.send(w_s, (uint8*)(req)+i, 1, MSG_NOSIGNAL);
          }
          continue;
        }
      }

        return_code = ctx.reply(query, return_code, modbus_mapping);
        if (return_code == -1) {
            break;
        }
    }


    stdout.printf("Quit the loop: %s\n", Modbus.strerror(errno));
    return 0;
  }
}

public static void main (string[] args) {
  var app = new UnitTestServer ();
  app.run (args);
}

