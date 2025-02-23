from xtore.service.StorageServer cimport StorageServer
from xtore.protocol.StorageTransferProtocol cimport StorageTransferProtocol
from xtore.BaseType cimport i32

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
	cdef StorageServer server
	cdef StorageTransferProtocol protocol

	cdef getParser(self, list argv) :
		self.parser = argparse.ArgumentParser(description=__help__, formatter_class=RawTextHelpFormatter)
		# self.parser.add_argument("-m", "--mode", help="Select load balance algorithm", required=False, type=str)
		self.option = self.parser.parse_args(argv)

	cdef getConfig(self) :
		cdef str configPath = os.path.join(sys.prefix, "etc", "xtore", "XtoreNetwork.json")
		cdef object fd
		with open(configPath, "rt") as fd :
			self.config = json.loads(fd.read())
			self.clusterConfig = self.config
			fd.close()

	cdef getStorageUnit(self) :
		cdef list storageUnits = []
		for layer in self.clusterConfig["primeRing"] :
			for storageUnit in layer["childStorageUnit"] :
				storageUnits.append(storageUnit["storageUnit"])
		return storageUnits

	# cdef spawnServer(self, list storageUnits) :
	# 	for storageUnit in storageUnits :
	# 		self.server = StorageServer(storageUnit["master"])
	# 		self.server.run()
	# 		for replica in storageUnit["replica"] :
	# 			self.server = StorageServer(replica)
	# 			self.server.run()

	cdef run(self, list argv) :
		self.getParser(argv)
		self.getConfig()
		self.server = StorageServer(self.clusterConfig["primeRing"][0]["childStorageUnit"][0]["storageUnit"]["master"])