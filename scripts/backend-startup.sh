#!/bin/bash
apt-get update
apt-get install -y openjdk-11-jdk
cat > /tmp/app.java << 'EOF'
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class SimpleHttpServer {
    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/", (exchange -> {
            String response = "Backend Server Response";
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }));
        server.setExecutor(null);
        server.start();
    }
}
EOF
javac /tmp/app.java
nohup java -cp /tmp SimpleHttpServer &
