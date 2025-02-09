import asyncio

cdef class StorageProtocol:
	def connection_made(self, object transport):
		self.transport = transport

	def connection_lost(self, Exception exc):
		self.transport = None

	def data_received(self, bytes data):
		# Decode the data

		# Check operation type

		# Perform operation

		# Send back the response
		self.transport.write(data)