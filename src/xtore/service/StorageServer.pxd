from xtore.BaseType cimport u16

cdef class StorageServer :
	cdef dict config
	cdef str host
	cdef u16 port