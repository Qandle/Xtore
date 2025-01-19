from xtore.BaseType cimport i32, i64
from cpython cimport array
import array

cdef class Datum:
    cdef i32 value
    cdef i64 key

cdef class ConsistentUnitStorage: #Node
    cdef i32 storageKey
    cdef i32 maxStorageSize
    cdef i32 usedStorageSize
    cdef object storage

    cdef appendData(self, datum)
    cdef findData(self, key)
    # cdef deleteData(self, key)
    # cdef bint isFull(self)

cdef class ConsistentHashing:
    cdef i32 ringId
    cdef i32 amountKey
    cdef i32 amountNode
    cdef array.array ring

    cdef appendData(self, data)
    cdef searchKey(key, self)
    # cdef removeKey(key, self)