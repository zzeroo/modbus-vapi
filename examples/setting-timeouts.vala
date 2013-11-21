using Modbus;

class SetTimeouts : GLib.Object {

    private Context ctx;

    public void run () {

        ctx = new Context.tcp ("10.0.1.77", TcpAttributes.DEFAULT_PORT);
		Posix.timeval timeout=Posix.timeval();
		
		//Getting response timeout
		ctx.get_response_timeout (&timeout);
        message ("timeout.tv_sec = %ld ", timeout.tv_sec);
        message ("timeout.tv_usec = %ld ", timeout.tv_usec);
        
        //Setting response timeout...
        timeout.tv_sec=1;
        timeout.tv_usec=500000;                  
        ctx.set_response_timeout (&timeout);              
        
        //...and getting response timeout again
        ctx.get_response_timeout (&timeout);
        message ("timeout.tv_sec = %ld ", timeout.tv_sec);
        message ("timeout.tv_usec = %ld ", timeout.tv_usec);        

        ctx.close ();
    }
}

public static int main (string[] args) {
    SetTimeouts app = new SetTimeouts ();
    app.run ();
    return 0;
}
