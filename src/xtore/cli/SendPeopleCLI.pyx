import re
from xtore.service.ClientService cimport ClientService
from xtore.common.Buffer cimport Buffer, initBuffer, releaseBuffer, setBuffer
from xtore.protocol.ClusterProtocol cimport ClusterProtocol, DatabaseOperation, InstanceType
from xtore.test.People cimport People
from xtore.BaseType cimport i32, i64

from libc.stdlib cimport malloc
from cpython cimport PyBytes_FromStringAndSize
from argparse import RawTextHelpFormatter

import os, sys, argparse, json, csv

cdef str __help__ = ""
cdef bint IS_VENV = sys.prefix != sys.base_prefix
cdef i32 BUFFER_SIZE = 1 << 16

def run():
	cdef SendPeopleCLI service = SendPeopleCLI()
	service.run(sys.argv[1:])

cdef class SendPeopleCLI :
	cdef object parser
	cdef object option
	cdef ClientService service
	cdef Buffer stream
	cdef Buffer received

	def __init__(self):
		initBuffer(&self.stream, <char *> malloc(BUFFER_SIZE), BUFFER_SIZE)
		initBuffer(&self.received, <char *> malloc(BUFFER_SIZE), BUFFER_SIZE)

	def __dealloc__(self):
		releaseBuffer(&self.stream)
		releaseBuffer(&self.received)

	cdef getParser(self, list argv) :
		self.parser = argparse.ArgumentParser(description=__help__, formatter_class=RawTextHelpFormatter)
		self.parser.add_argument("-u", "--host", help="Target Server host.", required=False, type=str, default='127.0.0.1')
		self.parser.add_argument("-p", "--port", help="Target Server port.", required=True, type=int)
		self.option = self.parser.parse_args(argv)

	cdef list[People] TSVToPeopleList(self, str filename) :
		cdef object fd
		cdef list[People] peopleList = []
		cdef People peopleRecord
		with open(filename, "rt") as fd :
			reader = csv.reader(fd, delimiter='\t')
			data = list(reader)
			for row in data[1:]:
				peopleRecord = People()
				peopleRecord.income = <i64> int(row[0])
				peopleRecord.name = row[1]
				peopleRecord.surname = row[2]
				peopleList.append(peopleRecord)
			fd.close()
		return peopleList

	cdef encodePeople(self, list peopleList) :
		cdef ClusterProtocol protocol = ClusterProtocol()
		protocol.registerClass("People", People)
		protocol.operation = DatabaseOperation.SET
		protocol.type = InstanceType.HASH
		protocol.tableName = "People"
		protocol.version = 1
		protocol.code(&self.stream, peopleList)
		print(f"Encoded People: {self.stream}")
		return PyBytes_FromStringAndSize(self.stream.buffer, self.stream.position)

	cdef list[People] decodePeople(self, Buffer *stream) :
		cdef ClusterProtocol protocol = ClusterProtocol()
		protocol.registerClass("People", People)
		protocol.getHeader(stream)
		print(f"Header: {protocol}")
		return protocol.decode(stream)

	cdef showPeople(self, list peopleList) :
		for people in peopleList:
			print(people)

	cdef handleEcho(self, bytes message) :
		cdef list[People] peopleList
		print(f"Recieved Buffer: {message}")
		setBuffer(&self.received, <char *> message, len(message))
		self.received.position -= len(message)
		print(f"Decoded People: {self.received}")
		peopleList = self.decodePeople(&self.received)
		self.showPeople(peopleList)

	cdef run(self, list argv) :
		self.getParser(argv)
		self.option.filename = "test.tsv"
		peopleList = self.TSVToPeopleList(self.option.filename)
		new_stream = self.encodePeople(peopleList)

		self.stream.position = 0
		# unpackpeopleList = self.decodePeople(&self.stream)
		# self.showPeople(unpackpeopleList)
		# self.handleEcho(new_stream)

		self.service = ClientService({
			"host": self.option.host,
			"port": self.option.port
		})
		self.service.send(new_stream, self.handleEcho)
