from xtore.test.PeopleHashStorage cimport PeopleHashStorage
from xtore.test.PeopleBSTStorage cimport PeopleBSTStorage
from xtore.test.PeopleRTStorage cimport PeopleRTStorage
from xtore.test.People cimport People
from xtore.common.StreamIOHandler cimport StreamIOHandler
from xtore.instance.HashIterator cimport HashIterator
from xtore.instance.BasicStorage cimport BasicStorage

from faker import Faker
from argparse import RawTextHelpFormatter

import os, sys, argparse, traceback, random, time

cdef str __help__ = "Test Script for Xtore"
cdef bint IS_VENV = sys.prefix != sys.base_prefix

def run():
	cli = DistributedDBCLI(DistributedDBCLI.getConfig())
	cli.run(sys.argv[1:])
cdef class DistributedDBCLI:
	cdef object parser
	cdef object option
	cdef object config

	def __init__(self, config):
		self.config = config
	
	def getParser(self, list argv):
		self.parser = argparse.ArgumentParser(description=__help__, formatter_class=RawTextHelpFormatter)
		self.parser.add_argument("test", help="Name of test", choices=[
			'People.Hash'
		])
		self.parser.add_argument("-n", "--count", help="Number of record to test.", required=True, type=int)
		self.parser.add_argument("-d", "--db", help="Number of db to test.", required=True, type=int)
		self.option = self.parser.parse_args(argv)

	cdef run(self, list argv):
		self.getParser(argv)
		self.checkPath()
		if self.option.test == 'People.Hash': self.testPeopleHashStorage()

	cdef testPeopleHashStorage(self):
		cdef str resourcePath = self.getResourcePath()
		print(resourcePath)
		cdef int db_num = self.option.db
		cdef str path
		cdef StreamIOHandler io
		cdef PeopleHashStorage storage
		cdef bint isNew
		for i in range(db_num):
			path = f'{resourcePath}/People_{i}.Hash.bin'
			print(path)
			io = StreamIOHandler(path)
			storage = PeopleHashStorage(io)
			isNew = not os.path.isfile(path)
			print(isNew)
			io.open()
			try:
				storage.enableIterable()
				if isNew: storage.create()
				else: storage.readHeader(0)
				peopleList = self.writePeople(storage)
				storedList = self.readPeople(storage, peopleList)
				self.comparePeople(peopleList, storedList)
				if isNew: self.iteratePeople(storage, peopleList)
				storage.writeHeader()
			except:
				print(traceback.format_exc())
			io.close()
	
	cdef list writePeople(self, BasicStorage storage):
		cdef list peopleList = []
		cdef People people
		cdef int i
		cdef int n = self.option.count
		cdef object fake = Faker()
		cdef double start = time.time()
		for i in range(n):
			people = People()
			people.position = -1
			people.ID = random.randint(1_000_000_000_000, 9_999_999_999_999)
			people.name = fake.first_name()
			people.surname = fake.last_name()
			peopleList.append(people)
		cdef double elapsed = time.time() - start
		print(f'>>> People Data of {n} are generated in {elapsed:.3}s')
		start = time.time()
		for people in peopleList:
			storage.set(people)
		elapsed = time.time() - start
		print(f'>>> People Data of {n} are stored in {elapsed:.3}s ({(n/elapsed)} r/s)')
		return peopleList
	
	cdef list readPeople(self, BasicStorage storage, list peopleList):
		cdef list storedList = []
		cdef People stored
		cdef double start = time.time()
		for people in peopleList:
			stored = storage.get(people, None)
			storedList.append(stored)
		cdef double elapsed = time.time() - start
		cdef int n = len(peopleList)
		print(f'>>> People Data of {n} are read in {elapsed:.3}s ({(n/elapsed)} r/s)')
		return storedList
	
	cdef comparePeople(self, list referenceList, list comparingList):
		cdef People reference, comparing
		cdef double start = time.time()
		for reference, comparing in zip(referenceList, comparingList):
			try:
				assert(reference.ID == comparing.ID)
				assert(reference.income == comparing.income)
				assert(reference.name == comparing.name)
				assert(reference.surname == comparing.surname)
			except Exception as error:
				print(reference, comparing)
				raise error
		cdef double elapsed = time.time() - start
		cdef int n = len(referenceList)
		print(f'>>> People Data of {n} are checked in {elapsed:.3}s')
	
	cdef iteratePeople(self, PeopleHashStorage storage, list referenceList):
		cdef HashIterator iterator
		cdef People entry = People()
		cdef People comparing
		cdef int i
		cdef int n = len(referenceList)
		cdef double start = time.time()
		cdef double elapsed
		if storage.isIterable:
			iterator = HashIterator(storage)
			iterator.start()
			while iterator.getNext(entry):
				continue
			elapsed = time.time() - start
			print(f'>>> People Data of {n} are iterated in {elapsed:.3}s ({(n/elapsed)} r/s)')

			i = 0
			iterator.start()
			while iterator.getNext(entry):
				comparing = referenceList[i]
				try:
					assert(entry.ID == comparing.ID)
					assert(entry.name == comparing.name)
					assert(entry.surname == comparing.surname)
				except Exception as error:
					print(entry, comparing)
					raise error
				i += 1
			elapsed = time.time() - start
			print(f'>>> People Data of {n} are checked in {elapsed:.3}s')

	cdef checkPath(self):
		cdef str resourcePath = self.getResourcePath()
		if not os.path.isdir(resourcePath): os.makedirs(resourcePath)

	cdef str getResourcePath(self):
		if IS_VENV: return (f'{sys.prefix}/var/xtore').encode('utf-8').decode('utf-8')
		else: return '/var/xtore'

	@staticmethod
	def getConfig():
		return {}