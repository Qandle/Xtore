import os
import time
import threading
from collections import defaultdict

cdef class PortMonitor:
    cdef public dict portCounts
    cdef list logFiles
    cdef str pattern

    def __init__(self, list logFiles):
        self.logFiles = logFiles
        self.portCounts = defaultdict(int)
        self.pattern = "number:"
    
    def _follow_file(self, str filepath):
        port = filepath.split("_")[-1].split(".")[0]
        with open(filepath, "r") as f:
            f.seek(0, os.SEEK_END)
            while True:
                line = f.readline()
                if not line:
                    time.sleep(0.1)
                    continue
                if line.startswith(self.pattern):
                    self.portCounts[port] += 1
                    print(f"[Port {port}] Count: {self.portCounts[port]}")
    
    def start(self):
        for fpath in self.logFiles:
            t = threading.Thread(target=self._follow_file, args=(fpath,))
            t.daemon = True
            t.start()

        # Keep main thread alive
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("Stopped.")
