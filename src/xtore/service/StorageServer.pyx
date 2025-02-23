from xtore.protocol.StorageTransferProtocol cimport StorageTransferProtocol

import asyncio, uvloop

cdef class StorageServer :
	def __init__(self, dict config) :
		self.config = config
		self.host = self.config["host"]
		self.port = self.config["port"]
	
	def run(self) :
		uvloop.install()
		asyncio.run(self.serve())

	async def serve(self) -> None :
		loop = asyncio.get_event_loop()
		server: object = await loop.create_server(lambda: StorageTransferProtocol(), self.host, self.port)
		print(f"Start Socket Server @ {self.host}:{self.port}")
		async with server:
			await server.serve_forever()
