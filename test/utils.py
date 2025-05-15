import numpy as np

def generate_uniform_ids(n, variance=10.0, max=1023):
    """
    Generate n roughly uniform IDs between 0 and 1023 with some random variance.
    
    Parameters:
    - n (int): Number of IDs to generate.
    - variance (float): Maximum random offset (±variance) to add to each ID.
    
    Returns:
    - list: List of generated IDs (clamped to [0, 1023]).
    """
    if n <= 0:
        return []
    
    circular_random = np.linspace(0, 2 * np.pi, n, endpoint=False)
    circular_mapping = (circular_random / (2 * np.pi) * max).astype(float)
    noisy_ids = circular_mapping + np.random.uniform(-variance, variance, n)  # random ±variance
    wrapped_ids = np.mod(noisy_ids, max).astype(int) # clamp to range [0, max]
    sorted_ids = np.sort(wrapped_ids)
    return sorted_ids.tolist()

def plot_ids_distribution(ids):
    """
    Plot the distribution of generated IDs.
    
    Parameters:
    - ids (list): List of IDs to plot.
    """
    import matplotlib.pyplot as plt
    
    plt.hist(ids, bins=range(0, 1024), alpha=1, color='blue', edgecolor='red', linewidth=1.5)
    plt.title('Distribution of Generated IDs')
    plt.xlabel('ID Value')
    plt.ylabel('Frequency')
    plt.xlim(0, 1023)
    plt.grid(axis='y', alpha=0.75)
    plt.show()

def uniformity_deviation(ids, max_val=1023, bins=10):
    """
    Computes how far the data's PDF deviates from a uniform distribution.
    
    Args:
        ids: List/array of IDs (0 to 1023).
        max_val: Maximum possible ID value (default=1023).
        bins: Number of bins for PDF estimation.
    
    Returns:
        Mean absolute deviation (MAD) from uniform PDF (lower = more uniform).
    """
    normalized = np.array(ids) / max_val
    counts, _ = np.histogram(normalized, bins=bins, density=True)
    uniform_pdf = np.ones(bins)
    mad = np.mean(np.abs(counts - uniform_pdf))
    return mad

def spacing_distribution(ids, max_val=1023):
    """
    Checks if data points are equally spaced (with optional circular wrapping).
    Returns the standard deviation of gaps (lower = more uniform).
    
    Args:
        ids: List of IDs (0 to max_val).
        max_val: Maximum ID value (default=1023).
    
    Returns:
        (gap_std, gap_mean) - Standard deviation and mean of gaps.
    """
    if len(ids) < 2:
        return (0.0, 0.0)
    
    sorted_ids = np.sort(ids)
    gaps = np.diff(sorted_ids)
    
    gaps = np.append(gaps, (max_val - sorted_ids[-1]) + sorted_ids[0])
    
    gap_std = np.std(gaps)
    gap_mean = np.mean(gaps)
    
    return (gap_std, gap_mean)   

if __name__ == "__main__":
    n = 38
    ids = generate_uniform_ids(n, variance=5)
    print(f"Generated {n} roughly uniform IDs with noise:")
    print(ids)
    plot_ids_distribution(ids)