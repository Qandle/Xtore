from xtore.instance.HashNode cimport HashNode
from xtore.common.Buffer cimport Buffer
from xtore.BaseType cimport i32, i64

cdef class HashPageNode(HashNode):
	cdef i64 pagePosition
	cdef i64 itemPosition
	
	cdef readItem(self, Buffer *stream)
	
	cdef writeUpperItem(self, Buffer *stream, i64 lowerPagePosition)
	cdef writeItem(self, Buffer *stream)
	# NOTE Like compare but for PageStorage
	# -1 : self <  other
	#  0 : self == other
	#  1 : self >  other
	cdef i32 comparePage(self, HashPageNode other)
	cdef copyPageKey(self, HashPageNode other)
	