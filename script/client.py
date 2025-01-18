import asyncio
import uvloop
import json
import sys
sys.path.append('/mnt/e/xtore/Xtore/src')
sys.path.append('/mnt/e/xtore/Xtore/build/lib.linux-x86_64-3.10')
asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

async def send_data():
    reader, writer = await asyncio.open_connection('127.0.0.1', 8888)
    command = {
        "test": "People.Hash",
        "count": 100 
    }
    data = json.dumps(command)
    print(f"Sending: {data}")
    writer.write(data.encode('utf-8'))
    await writer.drain()

    response = await reader.read(1024)
    print(f"Server response: {response.decode('utf-8')}")

    print("Closing the connection")
    writer.close()
    await writer.wait_closed()

if __name__ == '__main__':
    asyncio.run(send_data())
