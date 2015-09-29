[CCode (cprefix = "modbus_", cheader_filename = "modbus.h")]
namespace Modbus {

  [CCode (cname = "unsigned int", cprefix = "LIBMODBUS_VERSION_", cheader_filename = "modbus.h", has_type_id = false)]
  public enum Version {
    MAJOR,
    MINOR,
    MICRO,
    STRING,
    HEX
  }

  // FIXME: How?
 //  public const int FALSE = 0;
 //  [CCode (cheader_filename = "modbus.h")]
 //  public const int TRUE = 1;
 //  [CCode (cheader_filename = "modbus.h")]
 //  public const int ON = 1;
 //  [CCode (cheader_filename = "modbus.h")]
 //  public const int OFF = 0;

  [CCode (cname = "unsigned int", cprefix = "MODBUS_FC_", cheader_filename = "modbus.h", has_type_id = false)]
  public enum FunctionCode {
    READ_COILS,
    READ_DISCRETE_INPUTS,
    READ_HOLDING_REGISTERS,
    READ_INPUT_REGISTERS,
    WRITE_SINGLE_COIL,
    WRITE_SINGLE_REGISTER,
    READ_EXCEPTION_STATUS,
    WRITE_MULTIPLE_COILS,
    WRITE_MULTIPLE_REGISTERS,
    REPORT_SLAVE_ID,
    MASK_WRITE_REGISTER,
    WRITE_AND_READ_REGISTERS
  }

  [CCode (cname = "TRUE")]
  public const int TRUE;
  [CCode (cname = "FALSE")]
  public const int FALSE;
  [CCode (cname = "ON")]
  public const int ON;
  [CCode (cname = "OFF")]
  public const int OFF;

  [CCode (cprefix = "MODBUS_BROADCAST_ADDRESS", cheader_filename = "modbus.h")]
  public const int BROADCAST_ADDRESS;

  [CCode (cprefix = "MODBUS_TCP_SLAVE", cheader_filename = "modbus.h")]
  public const int TCP_SLAVE;


  [CCode (cname = "unsigned int", cprefix = "MODBUS_MAX_", cheader_filename = "modbus.h", has_type_id = false)]
  public enum Max {
    WR_WRITE_REGISTERS,
    WRITE_REGISTERS,
    READ_REGISTERS,
    WR_READ_REGISTERS,
    PDU_LENGTH,
    ADU_LENGTH,
    WRITE_BITS,
    READ_BITS
  }

  [CCode (cheader_filename = "modbus.h")]
  public const int MODBUS_ENOBASE;

  [CCode (cname = "unsigned int", cprefix = "MODBUS_EXCEPTION_", cheader_filename = "modbus.h", has_type_id = false)]
  public enum ModbusException {
    ILLEGAL_FUNCTION,
    ILLEGAL_DATA_ADDRESS,
    ILLEGAL_DATA_VALUE,
    SLAVE_OR_SERVER_FAILURE,
    ACKNOWLEDGE,
    SLAVE_OR_SERVER_BUSY,
    NEGATIVE_ACKNOWLEDGE,
    MEMORY_PARITY,
    NOT_DEFINED,
    GATEWAY_PATH,
    GATEWAY_TARGET,
    MAX
  }

  [CCode (cname = "EMBXILFUN")]
  public const int EMBXILFUN;
  [CCode (cname = "EMBXILADD")]
  public const int EMBXILADD;
  [CCode (cname = "EMBXILVAL")]
  public const int EMBXILVAL;
  [CCode (cname = "EMBXSFAIL")]
  public const int EMBXSFAIL;
  [CCode (cname = "EMBXACK")]
  public const int EMBXACK;
  [CCode (cname = "EMBXSBUSY")]
  public const int EMBXSBUSY;
  [CCode (cname = "EMBXNACK")]
  public const int EMBXNACK;
  [CCode (cname = "EMBXMEMPAR")]
  public const int EMBXMEMPAR;
  [CCode (cname = "EMBXGPATH")]
  public const int EMBXGPATH;
  [CCode (cname = "EMBXGTAR")]
  public const int EMBXGTAR;

  /* Native libmodbus error codes */
  [CCode (cname = "EMBBADCRC")]
  public const int EMBBADCRC;
  [CCode (cname = "EMBBADDATA")]
  public const int EMBBADDATA;
  [CCode (cname = "EMBBADEXC")]
  public const int EMBBADEXC;
  [CCode (cname = "EMBUNKEXC")]
  public const int EMBUNKEXC;
  [CCode (cname = "EMBMDATA")]
  public const int EMBMDATA;
  [CCode (cname = "EMBBADSLAVE")]
  public const int EMBBADSLAVE;

  [CCode (cheader_filename = "modbus.h")]
  public extern const int libmodbus_version_major;
  [CCode (cheader_filename = "modbus.h")]
  public extern const int libmodbus_version_minor;
  [CCode (cheader_filename = "modbus.h")]
  public extern const int libmodbus_version_micro;

  [CCode (cname = "modbus_mapping_t", cheader_filename = "modbus.h",
          unref_function = "", free_function = "modbus_mapping_free")]
  public class Mapping {
    public int nb_bits;
    public int offset_bits;
    public int nb_input_bits;
    public int offset_input_bits;
    public int nb_input_registers;
    public int offset_input_registers;
    public int nb_registers;
    public int offset_registers;
    [CCode (array_length_cname = "nb_bits")]
    public uint8[] tab_bits;
    [CCode (array_length_cname = "nb_input_bits")]
    public uint8[] tab_input_bits;
    [CCode (array_length_cname = "nb_input_registers")]
    public uint16[] tab_input_registers;
    [CCode (array_length_cname = "nb_registers")]
    public uint16[] tab_registers;

    [CCode (cname = "modbus_mapping_new")]
    public Mapping (int nb_bits, int nb_input_bits, int nb_registers, int nb_input_registers);
  }

  [CCode (cprefix = "MODBUS_ERROR_RECOVERY_", cheader_filename = "modbus.h", has_type_id = false)]
  public enum ErrorRecovery {
    NONE,
    LINK,
    PROTOCOL
  }

  [CCode (cname = "modbus_t", cprefix = "modbus_", cheader_filename = "modbus.h", unref_function = "", free_function = "modbus_free")]
  [Compact]
  public class Context {
    [CCode (cname = "modbus_new_rtu")]
    public Context.rtu (string? device, int baud, char parity, int data_bit, int stop_bit);

    [CCode (cname = "modbus_new_tcp")]
    public Context.tcp (string ip_address, int port);

    [CCode (cname = "modbus_new_tcp_pi")]
    public Context.tcp_pi (string? node, string? service);


    public void close ();
    public int connect ();
    public int flush ();

    public int set_slave (int slave);
    public int set_error_recovery (ErrorRecovery error_recovery);
    public int set_socket (int socket);
    public int get_socket ();
    public int get_response_timeout (uint32 *to_sec, uint32 *to_usec);
    public int set_response_timeout (uint32 to_sec, uint32 to_usec);
    public int get_byte_timeout (uint32 *to_sec, uint32 *to_usec);
    public int set_byte_timeout (uint32 to_sec, uint32 to_usec);
    public int get_header_length ();
    public int set_debug (int flag);
    public int read_bits (int addr, int length, [CCode (array_length = false)] uint8 *dest);
    public int read_input_bits (int addr, int num_bits, [CCode (array_length = false)] uint8 *dest);
    public int read_registers (int addr, int num_bits, [CCode (array_length_pos = 1.5)] uint16 *dest);
    public int read_input_registers (int addr, int num_bits, [CCode (array_length = false)] uint16 *dest);
    public int write_bit (int coil_addr, int status);
    public int write_register (int reg_addr, int value);
    public int write_bits (int addr, int num_bits, [CCode (array_length = false)] uint8 *data);
    public int write_registers (int addr, int num_bits, [CCode (array_length = false)] uint16 *data);
    public int mask_write_register (int addr, uint16 and_mask, uint16 or_mask);
    public int write_and_read_registers (int write_addr, int write_num_bits,
                                         uint16 *src, int read_addr, int num_bits,
                                         uint16 *dest);
    public int report_slave_id (int max_dest, uint8 *dest);
    public int send_raw_request ([CCode (array_length_pos = 1.5)] uint8 *raw_request, ulong length);
    // FIXME: test ref parameter to avoid the *
    public int receive ([CCode (array_length = false)] uint8 *request);
    public int receive_confirmation ([CCode (array_length = false)] uint8 *rsp);
    public int reply ([CCode (array_length_pos = 1.5)] uint8 *req, int index, Mapping mb_mapping);
    public int reply_exception ([CCode (array_length = false)] uint8 *req, uint exception_code);

    public int tcp_listen(int nb_connection);
    public int tcp_accept(int *socket);

    public int tcp_pi_listen(int nb_connection);
    public int tcp_pi_accept(int *socket);


    public int rtu_set_serial_mode (int mode);
    public int rtu_get_serial_mode ();

    public int rtu_set_rts (int mode);
    public int rtu_get_rts ();

    // FIXME: Don't know how to resolve this
    //MODBUS_API int modbus_rtu_set_custom_rts(modbus_t *ctx, void (*set_rts) (modbus_t *ctx, int on));
    //public int rtu_set_custom_rts (void (*set_rts) (int on));

    public int rtu_set_rts_delay (int us);
    public int rtu_get_rts_delay ();

  }

  /**
   * UTILS FUNCTIONS
   **/
  namespace Get {
    [CCode (cname = "MODBUS_GET_HIGH_BYTE")]
    //HIGH_BYTE(data) (((data) >> 8) & 0xFF)
    public char high_byte (int8 *data);
    [CCode (cname = "MODBUS_GET_LOW_BYTE")]
    //LOW_BYTE(data) ((data) & 0xFF)
    public char low_byte (int8 *data);
    [CCode (cname = "MODBUS_GET_INT64_FROM_INT16")]
    //INT64_FROM_INT16(tab_int16, index)
    public int64 int64_from_int16 (int16 *tab, int index);
    [CCode (cname = "MODBUS_GET_INT32_FROM_INT16")]
    //INT32_FROM_INT16(tab_int16, index) ((tab_int16[(index)] << 16) + tab_int16[(index) + 1])
    public int32 int32_from_int16 (int16 *tab, int index);
    [CCode (cname = "MODBUS_GET_INT16_FROM_INT8")]
    //INT16_FROM_INT8(tab_int8, index) ((tab_int8[(index)] << 8) + tab_int8[(index) + 1])
    public static int16 int16_from_int8 (uint8 *tab, int index);
  }

  namespace Set {
    [CCode (cname = "MODBUS_SET_INT16_TO_INT8")]
    //INT16_TO_INT8(tab_int8, index, value)
    public int8 int16_to_int8 (int16 *tab, int value, int number_of_bits);
    [CCode (cname = "MODBUS_SET_INT32_TO_INT16")]
    //INT32_TO_INT16(tab_int16, index, value)
    public int16[] int32_to_int16 (int32[] tab);
    [CCode (cname = "MODBUS_SET_INT64_TO_INT16")]
    //INT64_TO_INT16(tab_int16, index, value)
    public int16 int64_to_int16 (int64[] tab);
  }

  public static void set_bits_from_byte ([CCode (array_length = false)]  uint8 dest[], int index, uint8 value);
  public static void set_bits_from_bytes ([CCode (array_length = false)] uint8 dest[], int index, int num_bits, [CCode (array_length = false)] uint8[] tab_byte);

  public static uint8 get_byte_from_bits ([CCode (array_length_pos = 2.5)] uint8 *src, int num_bits, int index);
  public static float get_float ([CCode (array_length = false)] uint16 *src);
  public static float get_float_dcba ([CCode (array_length = false)] uint16 *src);
  public static void set_float (float f, [CCode (array_length = false)]  uint16 *dest);
  public static void set_float_dcba (float f, [CCode (array_length = false)]  uint16 *dest);

  public static unowned string strerror (int errnum);


  [CCode (cprefix = "MODBUS_RTU_MAX_ADU_LENGTH", cheader_filename = "modbus-rtu.h")]
  public const int RTU_MAX_ADU_LENGTH;


  [CCode (cprefix = "MODBUS_TCP_", cheader_filename = "modbus-tcp.h")]
  public enum TcpAttributes {
    DEFAULT_PORT,
    MAX_ADU_LENGTH,
    SLAVE
  }




}
