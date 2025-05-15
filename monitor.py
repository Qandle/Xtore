import re
from collections import Counter
import matplotlib.pyplot as plt

def count_ports_from_log(file_path):
    port_counter = Counter()
    pattern = re.compile(r"\(localhost:(\d+)\)")
    
    with open(file_path) as f:
        for line in f:
            match = pattern.search(line)
            if match:
                port = match.group(1)
                port_counter[port] += 1
    
    for port, count in sorted(port_counter.items()):
        print(f"Port {port} : {count} times")

count_ports_from_log("tmp/con/cli-con10k.log")
