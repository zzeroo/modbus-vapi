using Modbus;

class SimpleServer : GLib.Object {

  private int socket = -1;
  private Context ctx;
  private Mapping modbus_mapping;

  public SimpleServer () {
    ctx = new Context.tcp ("127.0.0.1", 1502);
    ctx.set_debug (1);
    ctx.set_slave (16);
    modbus_mapping = new Mapping (500, 500, 500, 500);
    socket = ctx.tcp_listen (1);
    ctx.tcp_accept (ref socket);
  }

  ~SimpleServer () {
    ctx.close ();
  }

  public void run () {
    for (;;) {
        // FIXME: vala Bug look here:
        // http://blog.gmane.org/gmane.comp.programming.vala/month=20150501
        //uint8 query[TcpAttributes.MAX_ADU_LENGTH];
        uint8 query[260];
        int rc;

        rc = ctx.receive(query);
        if (rc > 0) {
            /* rc is the query size */
            ctx.reply(query, modbus_mapping);
        } else if (rc == -1) {
            /* Connection closed by the client or error */
            break;
        }
    }

    message ("Quit the loop: ");
  }
}

int main (string[] args) {
  var app = new SimpleServer ();
  app.run ();

  return 0;
}

