from xtore.BaseType cimport i32, i64

from libc.stdlib cimport malloc, free
from uuid import uuid

from cpython cimport array
import array
import random

cdef class Datum:
    def __init__(self, data):
        self.value = data
        self.key = uuid.uuid4()

cdef class ConsistentUnitStorage:
    def __init__(self, storageKey, maxStorageSize):
        self.storageKey = storageKey
        self.maxStorageSize = maxStorageSize
        # self.storage = <i64 *> malloc(maxStorageSize * 4)
        self.storage = {}
        self.usedStorageSize = 0
    
    cdef appendData(self, datum):
        self.storage[datum.key] = datum.value
        self.usedStorageSize += 1

    cdef findData(self, key):
        return self.storage[key]

cdef class ConsistentHashing:
    def __init__(self, ringId, amountKey, amountNode):
        self.ringId = ringId
        self.amountKey = amountKey
        self.amountNode = amountNode
        self.ring = array.array()
        for key in range(self.amountKey):
            self.ring.extend([key])
        for node in range(self.amountNode):
            position = random.randint(0, len(self.ring) - 1)
            self.ring.insert(position,
                             ConsistentUnitStorage(node, self.amountKey))
        print("created ring success !")
        print("-----------------")

    cdef appendData(self, data):
        # prep - create datum
        datum = Datum(data)
        print("Append Data - key = {key}, value = {value}".format(key=datum.key,
                                                           value=datum.value))
        # first hashing it
        hashedKey = datum.key.int  # do later
        # second mod it
        ringIndex = hashedKey % self.amountKey
        # third find the node
        currentIndex = self.ring.index(ringIndex)
        while self.ring[currentIndex].__class__ != ConsistentUnitStorage:
            currentIndex += 1
            if currentIndex >= len(self.ring):
                currentIndex = 0
            # print(self.ring[currentIndex], self.ring[currentIndex].__class__)
        insertNode = self.ring[currentIndex]
        # fourth append it
        insertNode.appendData(datum)
        # pprint.pprint(self.ring[currentIndex].storage)
        print("-----------------")
        return datum

    cdef searchKey(self, key):
        # first hashing it
        hashedKey = key.int  # change it later
        # second mod it
        ringIndex = hashedKey % self.amountKey
        # third find the node
        currentIndex = self.ring.index(ringIndex)
        while self.ring[currentIndex].__class__ != ConsistentUnitStorage:
            currentIndex += 1
            if currentIndex >= len(self.ring):
                currentIndex = 0
            # print(self.ring[currentIndex], self.ring[currentIndex].__class__)
        foundNode = self.ring[currentIndex]
        # fourth show it
        # pprint.pprint(self.ring[currentIndex].storage)
        try:
            print("Key [{key}] Found: {data}".format(key=key, data=foundNode.storage[key]))
        except:
            print("No key founded")
        finally:
            print("-----------------")