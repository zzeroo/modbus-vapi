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

  // the terminating f forces vala to use float and not a double
  private const float UT_REAL = 916.540649f;
  private const uint32 UT_IREAL = 0x4465229a;
  // The terminating U forces vala to use unsigned int32
  private const uint32 UT_IREAL_DCBA = 0x9a226544U;
  // End unit-test.h

  private const uint8 SERVER_ID = 17;
  private const uint8 INVALID_SERVER_ID = 18;

  enum Mode {
    TCP,
    TCP_PI,
    RTU
  }

  private const int NB_REPORT_SLAVE_ID = 10;
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
  private int success = FALSE;

  // FIXME: Fix multiple version
  private void bug_report (bool condition, string format = "", int args = 0) {
    stdout.printf("\nLine %d: assertion error for '%s': "  + format + "\n", GLib.Log.LINE, condition, args);
  }

  // FIXME: Fix multiple version
  private void bug_report_f (bool condition, string format = "", float args = 0) {
    stdout.printf("\nLine %d: assertion error for '%s': "  + format + "\n", GLib.Log.LINE, condition, args);
  }

   public const int FALSE = 0;
   public const int TRUE = 1;
   public const int ON = 1;
   public const int OFF = 0;

   // FIXME: All the WIN32 from modbus-tcp.h
   // not working
   //public static int ETIMEDOUT = WSAETIMEDOUT;
   public const int ETIMEDOUT = -1;
   public const int EINVAL = -1;


  // FIXME: Fix multiple version
  private int assert_true_f (bool condition, string format = "", float args = 0, ...) {
    var l = va_list ();

    if (condition) {
      stdout.printf("OK\n");
      return 0;
    } else {
      bug_report_f (condition, format, args);
      ctx.set_response_timeout (old_response_to_sec, old_response_to_usec);
      return -1;
    }
  }

  // FIXME: Fix multiple version
  // FIXME: Fix version with false condition and multiple args. See line 170
  private int assert_true (bool condition, string format = "", int64 args = 0, ...) {
    var l = va_list ();

    if (condition) {
      stdout.printf("OK\n");
      return 0;
    } else {
      // FIXME: Fix this ugly cast
      bug_report (condition, format, (int)args);
      ctx.set_response_timeout (old_response_to_sec, old_response_to_usec);
      return -1;
    }
  }

  /* Send crafted requests to test server resilience
     and ensure proper exceptions are returned. */
  public int test_server (int use_backend) {
    return -1;
  }

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
      ctx.set_slave (SERVER_ID);
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
    assert_true (old_response_to_sec == new_response_to_sec &&
                old_response_to_usec == new_response_to_usec);

    /* Allocate and initialize the memory to store the bits */
    nb_points = (UT_BITS_NB > UT_INPUT_BITS_NB) ? UT_BITS_NB : UT_INPUT_BITS_NB;
    tab_rp_bits = (uint8 *) malloc(nb_points * sizeof(uint8));
    Posix.memset (tab_rp_bits, 0, nb_points * sizeof(uint8));

    /* Allocate and initialize the memory to store the registers */
    nb_points = (UT_REGISTERS_NB > UT_INPUT_REGISTERS_NB) ?
        UT_REGISTERS_NB : UT_INPUT_REGISTERS_NB;
    tab_rp_registers = (uint16 *) malloc(nb_points * sizeof(uint16));
    Posix.memset(tab_rp_registers, 0, nb_points * sizeof(uint16));

    stdout.printf("\nTEST WRITE/READ:\n");

    /** COIL BITS **/

    /* Single */
    return_code = ctx.write_bit (UT_BITS_ADDRESS, ON);
    stdout.printf ("1/2 modbus_write_bit: ");
    assert_true (return_code == 1);

    return_code = ctx.read_bits (UT_BITS_ADDRESS, 1, tab_rp_bits);
    stdout.printf ("2/2 modbus_read_bits: ");
    assert_true (return_code == 1, "FAILED (nb points %d)\n", return_code);
    assert_true (tab_rp_bits[0] == ON, "FAILED (%0X != %0X)\n",
                tab_rp_bits[0], ON);
    /* End single */

    /* Multiple bits */
    {
        uint8 tab_value[UT_BITS_NB];

        set_bits_from_bytes (tab_value, 0, UT_BITS_NB, UT_BITS_TAB);
        return_code = ctx.write_bits (UT_BITS_ADDRESS,
                               UT_BITS_NB, tab_value);
        stdout.printf ("1/2 modbus_write_bits: ");
        assert_true (return_code == UT_BITS_NB, "");
    }

    return_code = ctx.read_bits (UT_BITS_ADDRESS, UT_BITS_NB, tab_rp_bits);
    stdout.printf ("2/2 modbus_read_bits: ");
    assert_true (return_code == UT_BITS_NB, "FAILED (nb points %d)\n", return_code);

    i = 0;
    nb_points = UT_BITS_NB;
    while (nb_points > 0) {
        int nb_bits = (nb_points > 8) ? 8 : nb_points;

        value = get_byte_from_bits(tab_rp_bits, i*8, nb_bits);
        assert_true (value == UT_BITS_TAB[i], "FAILED (%0X != %0X)\n",
                    value, UT_BITS_TAB[i]);

        nb_points -= nb_bits;
        i++;
    }
    stdout.printf ("OK\n");
    /* End of multiple bits */

    /** DISCRETE INPUTS **/
    return_code = ctx.read_input_bits(UT_INPUT_BITS_ADDRESS,
                                UT_INPUT_BITS_NB, tab_rp_bits);
    stdout.printf ("1/1 modbus_read_input_bits: ");
    assert_true (return_code == UT_INPUT_BITS_NB, "FAILED (nb points %d)\n", return_code);

    i = 0;
    nb_points = UT_INPUT_BITS_NB;
    while (nb_points > 0) {
        int nb_bits = (nb_points > 8) ? 8 : nb_points;
        value = get_byte_from_bits(tab_rp_bits, i*8, nb_bits);
        assert_true (value == UT_INPUT_BITS_TAB[i], "FAILED (%0X != %0X)\n",
                    value, UT_INPUT_BITS_TAB[i]);

        nb_points -= nb_bits;
        i++;
    }
    stdout.printf ("OK\n");

    /** HOLDING REGISTERS **/

    /* Single register */
    return_code = ctx.write_register (UT_REGISTERS_ADDRESS, 0x1234);
    stdout.printf ("1/2 modbus_write_register: ");
    assert_true (return_code == 1, "");

    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS,
                               1, tab_rp_registers);
    stdout.printf ("2/2 modbus_read_registers: ");
    assert_true (return_code == 1, "FAILED (nb points %d)\n", return_code);
    assert_true (tab_rp_registers[0] == 0x1234, "FAILED (%0X != %0X)\n",
                tab_rp_registers[0], 0x1234);
    /* End of single register */

    /* Many registers */
    return_code = ctx.write_registers(UT_REGISTERS_ADDRESS,
                                UT_REGISTERS_NB, UT_REGISTERS_TAB);
    stdout.printf ("1/5 modbus_write_registers: ");
    assert_true (return_code == UT_REGISTERS_NB, "");

    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS,
                               UT_REGISTERS_NB, tab_rp_registers);
    stdout.printf ("2/5 modbus_read_registers: ");
    assert_true (return_code == UT_REGISTERS_NB, "FAILED (nb points %d)\n", return_code);

    for (i=0; i < UT_REGISTERS_NB; i++) {
        assert_true (tab_rp_registers[i] == UT_REGISTERS_TAB[i],
                    "FAILED (%0X != %0X)\n",
                    tab_rp_registers[i], UT_REGISTERS_TAB[i]);
    }

    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS,
                               0, tab_rp_registers);
    stdout.printf ("3/5 modbus_read_registers (0): ");
    assert_true (return_code == -1, "FAILED (nb_points %d)\n", return_code);

    nb_points = (UT_REGISTERS_NB >
                 UT_INPUT_REGISTERS_NB) ?
        UT_REGISTERS_NB : UT_INPUT_REGISTERS_NB;
    Posix.memset (tab_rp_registers, 0, nb_points * sizeof(uint16));

    /* Write registers to zero from tab_rp_registers and store read registers
       into tab_rp_registers. So the read registers must set to 0, except the
       first one because there is an offset of 1 register on write. */
    return_code = ctx.write_and_read_registers(
                                         UT_REGISTERS_ADDRESS + 1,
                                         UT_REGISTERS_NB - 1,
                                         tab_rp_registers,
                                         UT_REGISTERS_ADDRESS,
                                         UT_REGISTERS_NB,
                                         tab_rp_registers);
    stdout.printf ("4/5 modbus_write_and_read_registers: ");
    assert_true (return_code == UT_REGISTERS_NB, "FAILED (nb points %d != %d)\n",
                return_code, UT_REGISTERS_NB);

    assert_true (tab_rp_registers[0] == UT_REGISTERS_TAB[0],
                "FAILED (%0X != %0X)\n",
                tab_rp_registers[0], UT_REGISTERS_TAB[0]);

    for (i=1; i < UT_REGISTERS_NB; i++) {
        assert_true (tab_rp_registers[i] == 0, "FAILED (%0X != %0X)\n",
                    tab_rp_registers[i], 0);
    }

    /* End of many registers */


    /** INPUT REGISTERS **/
    return_code = ctx.read_input_registers(UT_INPUT_REGISTERS_ADDRESS,
                                     UT_INPUT_REGISTERS_NB,
                                     tab_rp_registers);
    stdout.printf ("1/1 modbus_read_input_registers: ");
    assert_true (return_code == UT_INPUT_REGISTERS_NB, "FAILED (nb points %d)\n", return_code);

    for (i=0; i < UT_INPUT_REGISTERS_NB; i++) {
        assert_true (tab_rp_registers[i] == UT_INPUT_REGISTERS_TAB[i],
                    "FAILED (%0X != %0X)\n",
                    tab_rp_registers[i], UT_INPUT_REGISTERS_TAB[i]);
    }

    stdout.printf ("\nTEST FLOATS\n");
    /** FLOAT **/
    stdout.printf ("1/4 Set float: ");
    set_float(UT_REAL, tab_rp_registers);
    if (tab_rp_registers[1] == (UT_IREAL >> 16) &&
        tab_rp_registers[0] == (UT_IREAL & 0xFFFF)) {
        stdout.printf ("OK\n");
    } else {
        /* Avoid *((uint32_t *)tab_rp_registers)
         * https://github.com/stephane/libmodbus/pull/104 */
        ireal = (uint32) tab_rp_registers[0] & 0xFFFF;
        ireal |= (uint32) tab_rp_registers[1] << 16;
        stdout.printf ("FAILED (%x != %x)\n", ireal, UT_IREAL);
        ctx.close ();
        return -1;
    }

    stdout.printf ("2/4 Get float: ");
    real = get_float(tab_rp_registers);
    assert_true_f (real == UT_REAL, "FAILED (%f != %f)\n", real, UT_REAL);

    stdout.printf ("3/4 Set float in DBCA order: ");
    set_float_dcba(UT_REAL, tab_rp_registers);
    ireal = (uint32) tab_rp_registers[0] & 0xFFFF;
    ireal |= (uint32) tab_rp_registers[1] << 16;
    assert_true (tab_rp_registers[1] == (UT_IREAL_DCBA >> 16) &&
                tab_rp_registers[0] == (UT_IREAL_DCBA & 0xFFFF),
                "FAILED (%x != %x)\n", ireal, UT_IREAL_DCBA);

    stdout.printf ("4/4 Get float in DCBA order: ");
    real = get_float_dcba(tab_rp_registers);
    assert_true_f (real == UT_REAL, "FAILED (%f != %f)\n", real, UT_REAL);

    /* MASKS */
    stdout.printf ("1/1 Write mask: ");
    return_code = ctx.write_register(UT_REGISTERS_ADDRESS, 0x12);
    return_code = ctx.mask_write_register(UT_REGISTERS_ADDRESS, 0xF2, 0x25);
    assert_true (return_code != -1, "FAILED (%x == -1)\n", return_code);
    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS, 1, tab_rp_registers);
    assert_true (tab_rp_registers[0] == 0x17,
                "FAILED (%0X != %0X)\n",
                tab_rp_registers[0], 0x17);

    stdout.printf ("\nAt this point, error messages doesn't mean the test has failed\n");

    /** ILLEGAL DATA ADDRESS **/
    stdout.printf ("\nTEST ILLEGAL DATA ADDRESS:\n");

    /* The mapping begins at 0 and ends at address + nb_points so
     * the addresses are not valid. */

    return_code = ctx.read_bits(UT_BITS_ADDRESS, UT_BITS_NB + 1, tab_rp_bits);
    stdout.printf ("* modbus_read_bits: ");
    assert_true (return_code == -1 && errno == EMBXILADD, "");

    return_code = ctx.read_input_bits(UT_INPUT_BITS_ADDRESS,
                                UT_INPUT_BITS_NB + 1, tab_rp_bits);
    stdout.printf ("* modbus_read_input_bits: ");
    assert_true (return_code == -1 && errno == EMBXILADD, "");

    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS,
                               UT_REGISTERS_NB + 1, tab_rp_registers);
    stdout.printf ("* modbus_read_registers: ");
    assert_true (return_code == -1 && errno == EMBXILADD, "");

    return_code = ctx.read_input_registers(UT_INPUT_REGISTERS_ADDRESS,
                                     UT_INPUT_REGISTERS_NB + 1,
                                     tab_rp_registers);
    stdout.printf ("* modbus_read_input_registers: ");
    assert_true (return_code == -1 && errno == EMBXILADD, "");

    return_code = ctx.write_bit(UT_BITS_ADDRESS + UT_BITS_NB, ON);
    stdout.printf ("* modbus_write_bit: ");
    assert_true (return_code == -1 && errno == EMBXILADD, "");

    return_code = ctx.write_bits(UT_BITS_ADDRESS + UT_BITS_NB,
                           UT_BITS_NB, tab_rp_bits);
    stdout.printf ("* modbus_write_coils: ");
    assert_true (return_code == -1 && errno == EMBXILADD, "");

    return_code = ctx.write_register(UT_REGISTERS_ADDRESS + UT_REGISTERS_NB,
                                tab_rp_registers[0]);
    stdout.printf ("* modbus_write_register: ");
    assert_true (return_code == -1 && errno == EMBXILADD, "");

    return_code = ctx.write_registers(UT_REGISTERS_ADDRESS + UT_REGISTERS_NB,
                               UT_REGISTERS_NB, tab_rp_registers);
    stdout.printf ("* modbus_write_registers: ");
    assert_true (return_code == -1 && errno == EMBXILADD, "");

    /** TOO MANY DATA **/
    stdout.printf ("\nTEST TOO MANY DATA ERROR:\n");

    return_code = ctx.read_bits(UT_BITS_ADDRESS,
                          Max.READ_BITS + 1, tab_rp_bits);
    stdout.printf ("* modbus_read_bits: ");
    assert_true (return_code == -1 && errno == EMBMDATA, "");

    return_code = ctx.read_input_bits(UT_INPUT_BITS_ADDRESS,
                                Max.READ_BITS + 1, tab_rp_bits);
    stdout.printf ("* modbus_read_input_bits: ");
    assert_true (return_code == -1 && errno == EMBMDATA, "");

    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS,
                               Max.READ_REGISTERS + 1,
                               tab_rp_registers);
    stdout.printf ("* modbus_read_registers: ");
    assert_true (return_code == -1 && errno == EMBMDATA, "");

    return_code = ctx.read_input_registers(UT_INPUT_REGISTERS_ADDRESS,
                                     Max.READ_REGISTERS + 1,
                                     tab_rp_registers);
    stdout.printf ("* modbus_read_input_registers: ");
    assert_true (return_code == -1 && errno == EMBMDATA, "");

    return_code = ctx.write_bits(UT_BITS_ADDRESS,
                           Max.WRITE_BITS + 1, tab_rp_bits);
    stdout.printf ("* modbus_write_bits: ");
    assert_true (return_code == -1 && errno == EMBMDATA, "");

    return_code = ctx.write_registers(UT_REGISTERS_ADDRESS,
                                Max.WRITE_REGISTERS + 1,
                                tab_rp_registers);
    stdout.printf ("* modbus_write_registers: ");
    assert_true (return_code == -1 && errno == EMBMDATA, "");

    /** SLAVE REPLY **/
    stdout.printf ("\nTEST SLAVE REPLY:\n");
    ctx.set_slave (INVALID_SERVER_ID);
    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS,
                               UT_REGISTERS_NB, tab_rp_registers);
    if (use_backend == Mode.RTU) {
        const int RAW_REQ_LENGTH = 6;
        uint8 raw_req[] = { INVALID_SERVER_ID, 0x03, 0x00, 0x01, 0x01, 0x01 };
        /* Too many points */
        uint8 raw_invalid_req[] = { INVALID_SERVER_ID, 0x03, 0x00, 0x01, 0xFF, 0xFF };
        const int RAW_REP_LENGTH = 7;
        uint8 raw_rep[] = { INVALID_SERVER_ID, 0x03, 0x04, 0, 0, 0, 0 };
        uint8 rsp[RTU_MAX_ADU_LENGTH];

        /* No response in RTU mode */
        stdout.printf ("1-A/3 No response from slave %d: ", INVALID_SERVER_ID);
        assert_true (return_code == -1 && errno == ETIMEDOUT, "");

        /* The slave raises a timeout on a confirmation to ignore because if an
         * indication for another slave is received, a confirmation must follow */


        /* Send a pair of indication/confirmation to the slave with a different
         * slave ID to simulate a communication on a RS485 bus. At first, the
         * slave will see the indication message then the confirmation, and it must
         * ignore both. */
        ctx.send_raw_request(raw_req, RAW_REQ_LENGTH * sizeof(uint8));
        ctx.send_raw_request(raw_rep, RAW_REP_LENGTH * sizeof(uint8));
        return_code = ctx.receive_confirmation(rsp);

        stdout.printf ("1-B/3 No response from slave %d on indication/confirmation messages: ",
               INVALID_SERVER_ID);
        assert_true (return_code == -1 && errno == ETIMEDOUT, "");

        /* Send an INVALID request for another slave */
        ctx.send_raw_request(raw_invalid_req, RAW_REQ_LENGTH * sizeof(uint8));
        return_code = ctx.receive_confirmation(rsp);

        stdout.printf ("1-C/3 No response from slave %d with invalid request: ",
               INVALID_SERVER_ID);
        assert_true (return_code == -1 && errno == ETIMEDOUT, "");
    } else {
        /* Response in TCP mode */
        stdout.printf ("1/3 Response from slave %d: ", INVALID_SERVER_ID);
        assert_true (return_code == UT_REGISTERS_NB, "");
    }

    return_code = ctx.set_slave (BROADCAST_ADDRESS);
    assert_true (return_code != -1, "Invalid broacast address");

    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS,
                               UT_REGISTERS_NB, tab_rp_registers);
    stdout.printf ("2/3 No reply after a broadcast query: ");
    assert_true (return_code == -1 && errno == ETIMEDOUT, "");

    /* Restore slave */
    if (use_backend == Mode.RTU) {
        ctx.set_slave (SERVER_ID);
    } else {
        ctx.set_slave (TCP_SLAVE);
    }

    stdout.printf ("3/3 Response with an invalid TID or slave: ");
    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS_INVALID_TID_OR_SLAVE,
                               1, tab_rp_registers);
    assert_true (return_code == -1, "");

    stdout.printf ("1/2 Report slave ID truncated: \n");
    /* Set a marker to ensure limit is respected */
    tab_rp_bits[NB_REPORT_SLAVE_ID - 1] = 42;
    return_code = ctx.report_slave_id (NB_REPORT_SLAVE_ID - 1, tab_rp_bits);
    /* Return the size required (response size) but respects the defined limit */
    assert_true (return_code == NB_REPORT_SLAVE_ID &&
                tab_rp_bits[NB_REPORT_SLAVE_ID - 1] == 42,
                "Return is return_code %d (%d) and marker is %d (42)",
                return_code, NB_REPORT_SLAVE_ID, tab_rp_bits[NB_REPORT_SLAVE_ID - 1]);

    stdout.printf ("2/2 Report slave ID: \n");
    /* tab_rp_bits is used to store bytes */
    return_code = ctx.report_slave_id (NB_REPORT_SLAVE_ID, tab_rp_bits);
    assert_true (return_code == NB_REPORT_SLAVE_ID, "");

    /* Slave ID is an arbitraty number for libmodbus */
    assert_true (return_code > 0, "");

    /* Run status indicator is ON */
    assert_true (return_code > 1 && tab_rp_bits[1] == 0xFF, "");

    /* Print additional data as string */
    if (return_code > 2) {
        stdout.printf ("Additional data: ");
        for (i=2; i < return_code; i++) {
            stdout.printf ("%c", tab_rp_bits[i]);
        }
        stdout.printf ("\n");
    }

    /* Save original timeout */
    ctx.get_response_timeout(&old_response_to_sec, &old_response_to_usec);
    ctx.get_byte_timeout(&old_byte_to_sec, &old_byte_to_usec);

    return_code = ctx.set_response_timeout(0, 0);
    stdout.printf ("1/6 Invalid response timeout (zero): ");
    assert_true (return_code == -1 && errno == EINVAL, "");

    return_code = ctx.set_response_timeout(0, 1000000);
    stdout.printf ("2/6 Invalid response timeout (too large us): ");
    assert_true (return_code == -1 && errno == EINVAL, "");

    return_code = ctx.set_byte_timeout(0, 1000000);
    stdout.printf ("3/6 Invalid byte timeout (too large us): ");
    assert_true (return_code == -1 && errno == EINVAL, "");

    ctx.set_response_timeout(0, 1);
    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS,
                               UT_REGISTERS_NB, tab_rp_registers);
    stdout.printf ("4/6 1us response timeout: ");
    if (return_code == -1 && errno == ETIMEDOUT) {
        stdout.printf ("OK\n");
    } else {
        stdout.printf ("FAILED (can fail on some platforms)\n");
    }

    /* A wait and flush operation is done by the error recovery code of
     * libmodbus but after a sleep of current response timeout
     * so 0 can be too short!
     */
    Posix.usleep(old_response_to_sec * 1000000 + old_response_to_usec);
    ctx.close ();

    /* Trigger a special behaviour on server to wait for 0.5 second before
     * replying whereas allowed timeout is 0.2 second */
    ctx.set_response_timeout(0, 200000);
    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS_SLEEP_500_MS,
                               1, tab_rp_registers);
    stdout.printf ("5/6 Too short response timeout (0.2s < 0.5s): ");
    assert_true (return_code == -1 && errno == ETIMEDOUT, "");

    /* Wait for reply (0.2 + 0.4 > 0.5 s) and flush before continue */
    Posix.usleep(400000);
    ctx.close ();

    ctx.set_response_timeout(0, 600000);
    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS_SLEEP_500_MS,
                               1, tab_rp_registers);
    stdout.printf ("6/6 Adequate response timeout (0.6s > 0.5s): ");
    assert_true (return_code == 1, "");

    /* Disable the byte timeout.
       The full response must be available in the 600ms interval */
    ctx.set_byte_timeout(0, 0);
    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS_SLEEP_500_MS,
                               1, tab_rp_registers);
    stdout.printf ("7/7 Disable byte timeout: ");
    assert_true (return_code == 1, "");

    /* Restore original response timeout */
    ctx.set_response_timeout(old_response_to_sec,
                                old_response_to_usec);

    if (use_backend == Mode.TCP) {
        /* The test server is only able to test byte timeouts with the TCP
         * backend */

        /* Timeout of 3ms between bytes */
        ctx.set_byte_timeout(0, 3000);
        return_code = ctx.read_registers(UT_REGISTERS_ADDRESS_BYTE_SLEEP_5_MS,
                                   1, tab_rp_registers);
        stdout.printf ("1/2 Too small byte timeout (3ms < 5ms): ");
        assert_true (return_code == -1 && errno == ETIMEDOUT, "");

        /* Wait remaing bytes before flushing */
        Posix.usleep(11 * 5000);
        ctx.close ();

        /* Timeout of 7ms between bytes */
        ctx.set_byte_timeout(0, 7000);
        return_code = ctx.read_registers(UT_REGISTERS_ADDRESS_BYTE_SLEEP_5_MS,
                                   1, tab_rp_registers);
        stdout.printf ("2/2 Adapted byte timeout (7ms > 5ms): ");
        assert_true (return_code == 1, "");
    }

    /* Restore original byte timeout */
    ctx.set_byte_timeout(old_byte_to_sec, old_byte_to_usec);

    /** BAD RESPONSE **/
    stdout.printf ("\nTEST BAD RESPONSE ERROR:\n");

    /* Allocate only the required space */
    tab_rp_registers_bad = (uint16 *) malloc(
        UT_REGISTERS_NB_SPECIAL * sizeof(uint16));

    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS,
                               UT_REGISTERS_NB_SPECIAL, tab_rp_registers_bad);
    stdout.printf ("* modbus_read_registers: ");
    assert_true (return_code == -1 && errno == EMBBADDATA, "");
    free(tab_rp_registers_bad);

    /** MANUAL EXCEPTION **/
    stdout.printf ("\nTEST MANUAL EXCEPTION:\n");
    return_code = ctx.read_registers(UT_REGISTERS_ADDRESS_SPECIAL,
                               UT_REGISTERS_NB, tab_rp_registers);

    stdout.printf ("* modbus_read_registers at special address: ");
    assert_true (return_code == -1 && errno == EMBXSBUSY, "");

    /** SERVER **/
    if (test_server (use_backend) == -1) {
        ctx.close ();
        return -1;
    }

    /* Test init functions */
    stdout.printf ("\nTEST INVALID INITIALIZATION:\n");
    ctx = new Context.rtu(null, 1, 'A', 0, 0);
    assert_true (ctx == null && errno == EINVAL, "");

    ctx = new Context.rtu("/dev/dummy", 0, 'A', 0, 0);
    assert_true (ctx == null && errno == EINVAL, "");

    ctx = new Context.tcp_pi(null, null);
    assert_true (ctx == null && errno == EINVAL, "");

    stdout.printf ("\nALL TESTS PASS WITH SUCCESS.\n");
    success = TRUE;




    return (success == TRUE) ? 0 : -1;
  }
}

public static void main (string[] args) {
  var app = new UnitTestClient ();
  app.run (args);
}

