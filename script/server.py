import asyncio
import uvloop
import sys
import json
sys.path.append('/mnt/e/xtore/Xtore/build/lib.linux-x86_64-3.10')
sys.path.append('/mnt/e/xtore/Xtore/src')
from xtore.cli.StorageTestCLI import StorageTestCLI, run

asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

"""async def handle_client(reader, writer):
    data = await reader.read(1024)
    message = data.decode('utf-8')
    print(f"Received: {message}")
    command = json.loads(message)
    test = command.get("test")
    count = command.get("count")
        
    if not test or not count:
        response = "Invalid command. Expected JSON with 'test' and 'count'."
        writer.write(response.encode('utf-8'))
        await writer.drain()
        writer.close()
        await writer.wait_closed()
        return


    cli = StorageTestCLI(StorageTestCLI.getConfig())
    cli.option = type('Options', (object,), {"test": 'People.Hash', "count": 5})
    cli.testPeopleHashStorage()

    response = "Data received and stored"
    writer.write(response.encode('utf-8'))
    await writer.drain()

    print("Closing connection")
    writer.close()
    await writer.wait_closed()
"""
async def handle_client(reader, writer):
    cli = None
    try:
        data = await reader.read(1024)
        message = data.decode('utf-8')
        print(f"Received: {message}")
        
        command = json.loads(message)
        test = command.get("test")
        count = command.get("count")
        
        if not test or not count:
            response = "Invalid command. Expected JSON with 'test' and 'count'."
            writer.write(response.encode('utf-8'))
            await writer.drain()
            writer.close()
            await writer.wait_closed()
            return
        
        argv = [test, "-n", str(count)]
        sys.argv = ["server.py"] + argv
        run() 
        response = f"Test {test} with count {count} completed successfully."
    except Exception as e:
        response = f"Error: {str(e)}"
    finally:
        writer.write(response.encode('utf-8'))
        await writer.drain()
        writer.close()
        await writer.wait_closed()

async def main():
    server = await asyncio.start_server(handle_client, '127.0.0.1', 8888)
    addrs = ', '.join(str(sock.getsockname()) for sock in server.sockets)
    print(f"Serving on {addrs}")

    async with server:
        await server.serve_forever()

if __name__ == '__main__':
    asyncio.run(main())
