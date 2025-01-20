from xtore.common.Server cimport Server

from faker import Faker
from argparse import RawTextHelpFormatter

import os, sys, argparse, traceback, random, time

cdef str __help__ = "Test Script for Xtore"
cdef bint IS_VENV = sys.prefix != sys.base_prefix

def run():
	cli = ServerCLI(ServerCLI.getConfig())
	cli.run(sys.argv[1:])
cdef class ServerCLI:
	cdef object parser
	cdef object option
	cdef object config

	def __init__(self, config):
		self.config = config
	
	def getParser(self, list argv):
		self.parser = argparse.ArgumentParser(description=__help__, formatter_class=RawTextHelpFormatter)
		self.parser.add_argument("-u", "--host", help="Server host.", required=False, type=str, default='127.0.0.1')
		self.parser.add_argument("-p", "--port", help="Server port.", required=True, type=int)
		self.option = self.parser.parse_args(argv)

	cdef run(self, list argv):
		self.getParser(argv)
		self.checkPath()
		self.startServer()

	cdef startServer(self):
		cdef Server server = Server(self.option.host, self.option.port)
		server.start()

	cdef checkPath(self):
		cdef str resourcePath = self.getResourcePath()
		if not os.path.isdir(resourcePath): os.makedirs(resourcePath)

	cdef str getResourcePath(self):
		if IS_VENV: return (f'{sys.prefix}/var/xtore').encode('utf-8').decode('utf-8')
		else: return '/var/xtore'

	@staticmethod
	def getConfig():
		return {}