using Modbus;

class RandomTestServer : GLib.Object {

  private int socket = -1;
  private Context ctx;
  private Mapping modbus_mapping;

  public RandomTestServer () {
    ctx = new Context.tcp ("127.0.0.1", 1502);
    modbus_mapping = new Mapping (500, 500, 500, 500);
    socket = ctx.tcp_listen (1);
    ctx.tcp_accept (ref socket);
  }

  ~RandomTestServer () {
    ctx.close ();
  }

  public void run () {
    for (;;) {
        uint8 query[TcpAttributes.MAX_ADU_LENGTH];
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
  var app = new RandomTestServer ();
  app.run ();

  return 0;
}
