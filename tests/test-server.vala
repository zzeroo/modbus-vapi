using Modbus;

class TestServer : GLib.Object {

  private Context ctx;

  public void run () {
    uint16 reg[2];

    ctx = new Context.tcp ("127.0.0.1", 1502);

    if (ctx.connect () == -1)
      error ("Connection failed.");
  }
}


int main (string[] args) {

  return 0;
}
