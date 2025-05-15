import json, os

def add_config(file_path):
    # load the configuration file
    with open(file_path, 'r') as f:
        config = json.load(f)

    # add the new node
    # first find the 