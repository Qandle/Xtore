cdef class Server:
    cdef str host
    cdef int port
    cdef object socket

    cdef get(self)
    cdef set(self)
    cdef start(self)
