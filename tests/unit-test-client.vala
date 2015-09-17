using Modbus;

class UnitTestClient : GLib.Object {

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
  // End unit-test.h

  private const uint8 SERVER_ID = 17;

  enum Mode {
    TCP,
    TCP_PI,
    RTU
  }

  private const uint8 NB_REPORT_SLAVE_ID = 10;
  private uint8 *tab_rp_bits = null;
  private uint16 *tab_rp_registers = null;
  private uint16 *tab_rp_registers_bad = null;
  private Context ctx;
  private int i; // for loop counter
  private uint8 value;
  private int nb_points;
  private int return_code;
  private float real;
  private uint32 ireal;
  private uint32 old_response_to_sec;
  private uint32 old_response_to_usec;
  private uint32 new_response_to_sec;
  private uint32 new_response_to_usec;
  private uint32 old_byte_to_sec;
  private uint32 old_byte_to_usec;
  private int use_backend;
  private bool success = false;


  public UnitTestClient () {
  }

  ~UnitTestClient () {
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
      stdout.printf ("Usage:\n  %s [tcp|tcppi|rtu] - Modbus client for unit testing\n\n", argv[0]);
      return -1;
    }

    if (use_backend == Mode.TCP) {
      ctx = new Context.tcp ("127.0.0.1", 1502);
    } else if (use_backend == Mode.TCP_PI) {
      ctx = new Context.tcp_pi ("::1", "1502");
    } else {
      ctx = new Context.rtu ("/dev/ttyUSB1", 115200, 'N', 8, 1);
    }
    if (ctx == null) {
      stderr.printf("Unable to allocate libmodbus context\n");
      return -1;
    }
    ctx.set_debug (1);
    ctx.set_error_recovery( ErrorRecovery.LINK |
                            ErrorRecovery.PROTOCOL);

    if (use_backend == Mode.RTU) {
      ctx.set_slave(SERVER_ID);
    }

    ctx.get_response_timeout (&old_response_to_sec, &old_response_to_usec);
    if (ctx.connect () == -1) {
        stderr.printf ("Connection failed: %s\n", Modbus.strerror(errno));
        ctx.close ();
        return -1;
    }
    ctx.get_response_timeout (&new_response_to_sec, &new_response_to_usec);

    stdout.printf ("** UNIT TESTING **\n");

    stdout.printf ("1/1 No response timeout modification on connect: ");
    assert (old_response_to_sec == new_response_to_sec &&
                old_response_to_usec == new_response_to_usec);




    return (success) ? 0 : -1;
  }
}

public static void main (string[] args) {
  var app = new UnitTestClient ();
  app.run (args);
}

