using Modbus;

class ReadRegisters : GLib.Object {

  private Context ctx;

  public ReadRegisters () {
    ctx = new Context.tcp ("127.0.0.1", 1502);
    ctx.set_debug (1);
  }

  ~ReadRegisters () {
    ctx.close ();
  }

  public void run () {
    uint16 reg[2];

    if (ctx.connect () == -1)
      error ("Connection failed.");

    if (ctx.read_registers (16, reg) == -1)
      error ("Modbus read error.");

    message ("reg = %d (0x%X)", reg[0], reg[0]);
    message ("reg = %d (0x%X)", reg[1], reg[1]);
    message ("reg = %f", Modbus.get_float (reg));
  }
}

int main (string[] args) {
  var app = new ReadRegisters ();
  app.run ();

  return 0;
}

