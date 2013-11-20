using Modbus;

class ReadRegisters : GLib.Object {

    private Context ctx;

    public void run () {
        uint16 reg[2];

        ctx = new Context.tcp ("10.0.1.77", TcpAttributes.DEFAULT_PORT);

        if (ctx.connect () == -1)
            error ("Connection failed.");

        if (ctx.read_registers (0x46, reg) == -1)
            error ("Modbus read error.");

        message ("reg = %d (0x%X)", reg[0], reg[0]);
        message ("reg = %d (0x%X)", reg[1], reg[1]);
        message ("reg = %f", Modbus.get_float (reg));

        ctx.close ();
    }
}

public static int main (string[] args) {
    ReadRegisters app = new ReadRegisters ();
    app.run ();
    return 0;
}
