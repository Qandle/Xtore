import socket

cdef class Server:
    def __init__(self, str host, int port):
        self.host = host
        self.port = port

    cdef get(self):
        print('not implemented')
        pass

    cdef set(self):
        print('not implemented')
        pass

    cdef start(self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.bind((self.host, self.port))
        self.socket.listen(5)
        print(f'Server is listening on {self.host}:{self.port}')
        while True:
            client, address = self.socket.accept()
            print(f'Connection from {address}')
            client.send('Hello'.encode())
            client.close()
        self.socket.close()