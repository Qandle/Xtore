from xtore.BaseType cimport i32
from xtore.algorithm.ConsistentHashing cimport ConsistentHashing
from xtore.instance.RecordNode cimport hashDJB
from xtore.algorithm.ConsistentNode cimport ConsistentNode

from xtore.algorithm.PrimeNode cimport PrimeNode
from xtore.algorithm.StorageUnit cimport StorageUnit
from xtore.algorithm.PrimeRing cimport PrimeRing

from libc.stdlib cimport malloc
from libc.string cimport memcpy
from cpython cimport PyBytes_FromStringAndSize
from argparse import RawTextHelpFormatter
import os, sys, argparse, json

cdef str __help__ = ""
cdef bint IS_VENV = sys.prefix != sys.base_prefix
cdef i32 BUFFER_SIZE = 1 << 16

def run():
	cli = AlgorithmTestCLI()
	cli.run(sys.argv[1:])

cdef class AlgorithmTestCLI:
	cdef object parser
	cdef object option
	cdef dict config
	cdef ConsistentHashing ring
	cdef PrimeRing primeRing

	def getParser(self, list argv):
		self.parser = argparse.ArgumentParser(description=__help__, formatter_class=RawTextHelpFormatter)
		self.parser.add_argument("-s", "--algorithm", help="Select Algorithm [CH - consistent hashing, PR - prime ring]", required=True, choices=['CH', 'PR'])
		self.parser.add_argument("-f", "--file", help="Filename", required=True, type=str)
		self.option = self.parser.parse_args(argv)

	cdef run(self, list argv):
		self.getParser(argv)
		self.getConfig()
		if self.option.algorithm == "CH":
			self.ring = ConsistentHashing(replicationFactor = self.config["replicationFactor"], maxNode=self.config["maxNode"])
			self.ring.loadData(self.config["nodeList"])
			keylist = self.readKey(self.option.file)
			self.getNodeFromKeyConsistent(keylist, self.ring)
		else:
			self.primeRing = PrimeRing(primeNumbers = self.config["primeNumbers"], replicaNumber=self.config["replicaNumber"])
			self.primeRing.loadData(self.config["nodeList"])
			keylist = self.readKey(self.option.file)
			self.getNodeFromKeyPrimeRing(keylist, self.primeRing)

	
	cdef getConfig(self):
		cdef str configPath = os.path.join(sys.prefix, "etc", "xtore", "Test.json")
		cdef object fd
		with open(configPath, "rt") as fd :
			self.config = json.loads(fd.read())
			fd.close()

	cdef setConfig(self):
		cdef str configPath = os.path.join(sys.prefix, "etc", "xtore", "Test.json")
		cdef object fd
		with open(configPath, "w") as fd :
			json.dump(self.config, fd, indent=4)

	cdef getNodeFromKeyConsistent(self, list keyList, ConsistentHashing consistentHashing):
		cdef list[ConsistentNode] nodeList
		cdef list data = []
		cdef ConsistentNode node
		for key in keyList:
			nodeList = consistentHashing.getNodeList(key)
			for _node in nodeList:
				node = _node
				print(f"[T{key}]({node.host}:{node.port})")

	cdef getNodeFromKeyPrimeRing(self, list keyList, PrimeRing primeRing):
		cdef StorageUnit storageUnit
		cdef PrimeNode node
		cdef list data = []
		for key in keyList:
			storageUnit = primeRing.getStorageUnit(key)[-1]
			nodeList = storageUnit.nodes.values()
			for replica in nodeList:
				node = replica
				print(f"[T{key}]({node.host}:{node.port})")

	cdef readKeyFile(self, str filename):
		cdef object fd
		with open(filename, "rt") as fd :
			data = fd.read()
			fd.close()
		return data.splitlines()

	cdef readKey(self, str filename):
		cdef list data = self.readKeyFile(filename)
		cdef list keyList = [int(a.split("\t")[0]) for a in data[1:]]
		print(keyList)
		return keyList