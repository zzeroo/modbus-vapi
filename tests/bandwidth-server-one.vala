using Modbus;

class BandwidthServerOne : GLib.Object {

  private Context ctx;
  private int socket = -1;
  private Mapping modbus_mapping;

  public BandwidthServerOne () {
    ctx = new Context.tcp ("127.0.0.1", 1502);
    socket = ctx.tcp_listen (1);
    ctx.tcp_accept (ref socket);
    message ("Create new Modbus.Mapping with MAX_READ_BITS: %d", Max.READ_BITS);
  }

  ~BandwidthServerOne () {
    ctx.close ();
  }

  public void run () {
    message ("Create new Modbus.Mapping with MAX_READ_BITS: %d", Max.READ_BITS);
  }
}

int main (string[] args) {
  var app = new BandwidthServerOne ();
  app.run ();

  return 0;
}

