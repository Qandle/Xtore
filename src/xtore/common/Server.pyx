import asyncio
import uvloop
import sys
import json

async def handleClient(reader, writer):
    cli = None
    try:
        data = await reader.read(1024)
        message = data.decode('utf-8')
        print(f"Received: {message}")
        
        command = json.loads(message)
        test = command.get("test")
        count = command.get("count")
        
        if not test or not count:
            response = "Invalid command"
            writer.write(response.encode('utf-8'))
            await writer.drain()
            writer.close()
            await writer.wait_closed()
            return
        
        # argv = [test, "-n", str(count)]
        # sys.argv = ["server.py"] + argv
        # run() 
        response = f"successfully"
    except Exception as e:
        response = f"Error: {str(e)}"
    finally:
        writer.write(response.encode('utf-8'))
        await writer.drain()
        writer.close()
        await writer.wait_closed()

async def main(url, port) -> None:
    server = await asyncio.start_server(handleClient, url, port)
    addrs = ', '.join(str(sock.getsockname()) for sock in server.sockets)
    print(f"Serving on {addrs}")

    async with server:
        await server.serve_forever()

cdef class Server:
    def __init__(self, str host, int port):
        self.host = host
        self.port = port

    cdef get(self):
        print('not implemented')
        pass

    cdef set(self):
        print('not implemented')
        pass

    cdef start(self):
        asyncio.run(main(self.host, self.port))



