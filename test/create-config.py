from utils import generate_uniform_ids, spacing_distribution, plot_ids_distribution
import json

def create_config(name, n, variance=10.0, max=1023, start_port=7001, replicationFactor=1):
    ids = generate_uniform_ids(n, variance, max)
    spacing = spacing_distribution(ids, max_val=max)

    config = {
        "replicationFactor": replicationFactor,
        "maxNode": max,
        "nodeList": dict(),
        "spacing": spacing
    }

    for i in range(n):
        config["nodeList"][f"{i}"] = {
            "id": ids[i],
            "host": f"localhost",
            "port": start_port + i,
        }
    
    with open(f'test/config/config-{name}.json', 'w') as f:
        json.dump(config, f, indent=4)
    
    print(f"Configuration file 'test/configtest/config-{name}.json' created with {n} IDs.")
    print(f"Spacing distribution - STD: {spacing[0]}, MEAN: {spacing[1]}")


if __name__ == "__main__":
    # create_config("8n-1r-10v-127m", 8, variance=10, max=127)
    create_config("38n-1r-10v-256m", 38, variance=10, max=255, replicationFactor=3)
    create_config("38n-1r-10v-512m", 38, variance=10, max=511, replicationFactor=3)
    create_config("38n-1r-10v-768m", 38, variance=10, max=767, replicationFactor=3)
    create_config("38n-1r-10v-1024m", 38, variance=10, max=1023, replicationFactor=3)

    create_config("38n-1r-40v-1024m", 38, variance=40, max=1023, replicationFactor=3)
    create_config("38n-1r-70v-1024m", 38, variance=70, max=1023, replicationFactor=3)
    create_config("38n-1r-100v-1024m", 38, variance=100, max=1023, replicationFactor=3)
