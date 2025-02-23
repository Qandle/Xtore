from xtore.BaseType cimport i32, i64
from xtore.common.Buffer cimport Buffer, PyBytes_FromStringAndSize, getBuffer, initBuffer, releaseBuffer, setBuffer, setBytes

from xtore.common.StreamIOHandler cimport StreamIOHandler
from xtore.common.ReplicaIOHandler cimport ReplicaIOHandler
from xtore.instance.BasicIterator cimport BasicIterator
from xtore.instance.HashIterator cimport HashIterator
from xtore.instance.RecordNode cimport RecordNode
from xtore.test.People cimport People
from xtore.test.PeopleBSTStorage cimport PeopleBSTStorage
from xtore.test.PeopleHashStorage cimport PeopleHashStorage
from xtore.test.PeopleRTStorage cimport PeopleRTStorage

from libc.stdlib cimport malloc

import os, sys, traceback, uuid

cdef bint IS_VENV = sys.prefix != sys.base_prefix

cdef i32 BUFFER_SIZE = 1 << 16
cdef i32 BST_NODE_OFFSET = 24

cdef class StorageService:
	def __init__(self, dict config):
		self.config = config
		initBuffer(&self.buffer, <char *> malloc(BUFFER_SIZE), BUFFER_SIZE)

	def __dealloc__(self):
		releaseBuffer(&self.buffer)

	cdef assignID(self, People record):
		record.ID = uuid.uuid4()

	cdef writeHashStorage(self, list[People] dataList):
		cdef str resourcePath = self.getResourcePath()
		cdef str path = f'{resourcePath}/People.{uuid.uuid4().int}.Hash.bin'
		cdef StreamIOHandler io = StreamIOHandler(path)
		cdef PeopleHashStorage storage = PeopleHashStorage(io)
		cdef bint isNew = not os.path.isfile(path)
		io.open()
		try:
			if isNew: storage.create()
			else: storage.readHeader(0)
			self.writeData(storage, dataList)
			storage.writeHeader()
		except:
			print(traceback.format_exc())
		io.close()

	cdef writeRTStorage(self, list[People] dataList):
		cdef str resourcePath = self.getResourcePath()
		cdef str path = f'{resourcePath}/People.RT.bin'
		cdef StreamIOHandler io = StreamIOHandler(path)
		cdef PeopleRTStorage storage = PeopleRTStorage(io)
		cdef bint isNew = not os.path.isfile(path)
		io.open()
		try:
			if isNew: storage.create()
			else: storage.readHeader(0)
			self.writeData(storage, dataList)
			storage.writeHeader()
		except:
			print(traceback.format_exc())
		io.close()

	cdef writeBSTStorage(self, list[People] dataList):
		cdef str resourcePath = self.getResourcePath()
		cdef str fileName = "People.BST.bin"
		cdef str path = os.path.join(resourcePath, fileName)
		cdef ReplicaIOHandler io = ReplicaIOHandler(path)
		cdef PeopleBSTStorage storage = PeopleBSTStorage(io)
		cdef bint isNew = not os.path.isfile(path)
		io.open()
		try:
			if isNew: storage.create()
			else: storage.readHeader(0)
			self.writeData(storage, dataList)
			storage.writeHeader()
		except:
			print(traceback.format_exc())
		io.close()

	cdef writeData(self, BasicStorage storage, list[RecordNode] dataList):
		cdef i32 i = 0
		cdef i32 dataLength = len(dataList)
		cdef RecordNode node
		cdef bytes uuidBytes
		for data in range(dataLength):
			uuidBytes = uuid.uuid4().bytes[:8]
			self.buffer.position = 0
			setBuffer(&self.buffer, <char *> uuidBytes, 8)
			node = dataList[data]
			self.buffer.position = 0
			node.readKey(1, &self.buffer)
			storage.set(node)
			print(node)
			i += 1
		print(f"Success Recorded {i} Records !")

	cdef readHashStorage(self, str storageName):
		cdef str resourcePath = self.getResourcePath()
		cdef str path = f'{resourcePath}/{storageName}.bin'
		print(f'storage path: {path}')
		cdef StreamIOHandler io = StreamIOHandler(path)
		cdef PeopleHashStorage storage = PeopleHashStorage(io)
		cdef bint isNew = not os.path.isfile(path)
		cdef list[RecordNode] nodeList = []
		cdef People entry = People()
		cdef int n = 0
		io.open()
		try:
			if isNew: print(f'Storage not found!')
			else: 
				storage.readHeader(0)
				for a in range(393000, 394231):
					try:
						node = storage.readNodeKey(a, None)
						storage.readNodeValue(node)
						print(f'a: {a}', end='\t')
						print(node)
					except:
						continue
				storage.readNodeValue(node)
				nodeList.append(node)
				print(node)
		except:
			print(traceback.format_exc())
		io.close()

	cdef readRTStorage(self, str storageName):
		cdef str resourcePath = self.getResourcePath()
		cdef str path = f'{resourcePath}/People.RT.bin'
		print(f'storage path: {path}')
		cdef StreamIOHandler io = StreamIOHandler(path)
		cdef PeopleRTStorage storage = PeopleRTStorage(io)
		cdef bint isNew = not os.path.isfile(path)
		cdef list[RecordNode] nodeList = []
		cdef People entry = People()
		cdef int n = 0
		io.open()
		try:
			if isNew: print(f'Storage not found!')
			else: 
				storage.readHeader(0)
				for a in range(storage.headerSize, io.getTail()):
					try:
						node = storage.readNodeKey(a, None)
						storage.readNodeValue(node)
						print(f'a: {a}', end='\t')
						print(node)
					except:
						continue
				storage.readNodeValue(node)
				nodeList.append(node)
				print(node)
		except:
			print(traceback.format_exc())
		io.close()

	cdef list[RecordNode] readBSTStorage(self, str storageName):
		cdef str resourcePath = self.getResourcePath()
		cdef str path = f'{resourcePath}/People.BST.bin'
		print(f'storage path: {path}')
		cdef StreamIOHandler io = StreamIOHandler(path)
		cdef PeopleBSTStorage storage = PeopleBSTStorage(io)
		cdef bint isNew = not os.path.isfile(path)
		cdef int n = 0

		cdef i64 position
		cdef i64 nodePosition
		cdef i64 left
		cdef i64 right
		cdef list stack = []
		cdef list[RecordNode] nodeList = []
		cdef People node = People()

		io.open()
		try:
			if isNew: print(f'Storage not found!')
			else: 
				storage.readHeader(0)
				position = storage.rootNodePosition
				while stack or position > 0:
					while position > 0:
						stack.append(position)
						storage.io.seek(position)
						storage.io.read(&storage.stream, BST_NODE_OFFSET)
						nodePosition = (<i64*> getBuffer(&storage.stream, 8))[0]
						left = (<i64*> getBuffer(&storage.stream, 8))[0]
						right = (<i64*> getBuffer(&storage.stream, 8))[0]
						position = left

					if len(stack) > 0:
						position = stack.pop()
						storage.io.seek(position)
						storage.io.read(&storage.stream, BST_NODE_OFFSET)
						nodePosition = (<i64*> getBuffer(&storage.stream, 8))[0]
						left = (<i64*> getBuffer(&storage.stream, 8))[0]
						right = (<i64*> getBuffer(&storage.stream, 8))[0]

						node = storage.readNodeKey(nodePosition, None)
						storage.readNodeValue(node)
						nodeList.append(node)

					position = right

				for record in nodeList:
					print(record)
		except:
			print(traceback.format_exc())
		io.close()
		return nodeList

	cdef readAllData(self, BasicStorage storage):
		pass
		
	cdef checkPath(self):
		cdef str resourcePath = self.getResourcePath()
		if not os.path.isdir(resourcePath): os.makedirs(resourcePath)

	cdef str getResourcePath(self):
		if IS_VENV: return (f'{sys.prefix}/var/xtore').encode('utf-8').decode('utf-8')
		else: return '/var/xtore'