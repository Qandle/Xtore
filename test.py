import asyncio
import pickle

asyncio.Protocol

def read_tsv(file_path: str, array: list):
	with open(file_path, "r") as file:
		i = 0
		for line in file:
			if i == 0:
				i += 1
				continue
			array.append(line)

async def tcp_client(host: str, port: int, message: str):
	reader, writer = await asyncio.open_connection(host, port)	
	print(f"Sending: {message}")
	writer.write(message)
	await writer.drain()
	
	data = await reader.read(2048)
	print(f"Received: {pickle.loads(data)}")
	
	writer.close()
	await writer.wait_closed()

async def main():
	host = "127.0.0.1"  # Update with your server's IP if needed
	port = 45001         # Ensure this matches your server's port
	people = []
	read_tsv("test.tsv", people)
	message = pickle.dumps(people)
	print(people)
	await tcp_client(host, port, message)

asyncio.run(main())