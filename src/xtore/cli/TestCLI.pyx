import re
from xtore.service.ClientService cimport ClientService
from xtore.service.UVServerService cimport UVServerService
from xtore.common.Buffer cimport Buffer, getBuffer, initBuffer, releaseBuffer, setBuffer
from xtore.common.Package cimport Package
from xtore.protocol.AsyncProtocol cimport AsyncProtocol
# from xtore.protocol.EchoProtocol cimport EchoProtocol
from xtore.protocol.ClusterProtocol cimport ClusterProtocol, DatabaseOperation, InstanceType
from xtore.BaseType cimport i32

from libc.stdlib cimport malloc
from libc.string cimport memcpy
from cpython cimport PyBytes_FromStringAndSize
from argparse import RawTextHelpFormatter
import os, sys, argparse, json

cdef str __help__ = ""
cdef bint IS_VENV = sys.prefix != sys.base_prefix
cdef i32 BUFFER_SIZE = 1 << 16

def run():
	cdef TestCLI service = TestCLI()
	service.run(sys.argv[1:])

cdef class TestCLI :
	cdef dict config
	cdef dict clusterConfig
	cdef object parser
	cdef object option
	cdef UVServerService serverService
	cdef ClusterProtocol protocol
	cdef Buffer stream
	cdef Buffer sendBack

	def __init__(self):
		initBuffer(&self.stream, <char *> malloc(BUFFER_SIZE), BUFFER_SIZE)
	
	def __dealloc__(self):
		releaseBuffer(&self.stream)

	cdef getParser(self, list argv) :
		self.parser = argparse.ArgumentParser(description=__help__, formatter_class=RawTextHelpFormatter)
		# self.parser.add_argument("-m", "--mode", help="Select load balance algorithm", required=False, type=str)
		self.option = self.parser.parse_args(argv)

	cdef getConfig(self) :
		cdef str configPath = os.path.join(sys.prefix, "etc", "xtore", "XtoreNetwork.json")
		cdef object fd
		with open(configPath, "rt") as fd :
			self.config = json.loads(fd.read())
			self.clusterConfig = self.config["cluster"] 
			fd.close()

	cdef run(self, list argv) :
		self.getParser(argv)
		self.getConfig()
		self.serverService = UVServerService(self.config["cluster"])
		protocol = ClusterProtocol()
		self.serverService.run(protocol)
