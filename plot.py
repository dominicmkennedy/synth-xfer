import re, math
import matplotlib.pyplot as plt
import numpy as np

def parse_infolog_exactness(file_path):
    """
    Parses info.log to extract exactness percentages
    Returns a list: [top_exactness, iter_0_exactness, iter_1_exactness, ...]
    """
    exactness_scores = []
    
    try:
        with open(file_path, 'r') as file:
            content = file.read()
            
        # 1. Extract 'Top Solution' Exactness
        # Looks for the pattern: Top Solution | Exact 60.3200% |
        top_match = re.search(r"Top Solution\s*\|\s*Exact\s*(\d+\.\d+)%", content)
        if top_match:
            exactness_scores.append(float(top_match.group(1)))
        else:
            print(f"Warning: 'Top Solution' format not found in {file_path}")

        # 2. Extract Iteration Exactness
        # Looks for the "Result of Current Solution" block followed by "exact%: "
        # We use re.DOTALL so the dot (.) matches newlines, capturing the multi-line block.
        # Pattern:
        # Result of Current Solution: 
        # bw: 8, dist: 596.88, exact%: 60.3200
        iter_matches = re.findall(r"Result of Current Solution:.*?exact%:\s*(\d+\.\d+)", content, re.DOTALL)
        
        # Convert strings to floats and add to list
        for match in iter_matches:
            exactness_scores.append(float(match))
            
        return exactness_scores

    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return []

def parse_perflog_times(file_path):
    """
    Parses a performance log file to extract the time taken for each iteration.
    Returns a list of floats: [iter 0 time, iter 1 time, ...]
    """
    iter_times = []
    
    try:
        with open(file_path, 'r') as file:
            content = file.read()
            
        # Regex to match the pattern: "Iter <number> took <time>s"
        # \s+ matches one or more whitespace characters
        # (\d+\.\d+) captures the floating point time value
        pattern = r"Iter\s+\d+\s+took\s+(\d+\.\d+)s"
        
        matches = re.findall(pattern, content)
        
        # Convert strings to floats
        iter_times = [float(time) for time in matches]
        
        return iter_times

    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return []


if __name__ == "__main__":
    # Define your file lists
    log_files = ['outputs/abds/info-abds.log', 'outputs/add/info-add.log', 'outputs/ashr/info-ashr.log']
    perf_files = ['outputs/abds/perf-abds.log', 'outputs/add/perf-add.log', 'outputs/ashr/perf-ashr.log']

    # 1. Setup the grid dimensions
    num_plots = len(log_files)
    cols = 3  # Number of columns you want
    rows = math.ceil(num_plots / cols)

    plt.style.use('bmh')
    
    # Create the figure and subplots
    # figsize is (width, height) - adjusted here to give each plot enough room
    fig, axes = plt.subplots(rows, cols, figsize=(5 * cols, 4 * rows))
    
    # Flatten axes array for easy iteration (handles 1D or 2D arrays automatically)
    # If there is only 1 plot, axes is not a list, so we wrap it.
    if num_plots == 1:
        axes_flat = [axes]
    else:
        axes_flat = axes.flatten()

    # 2. Iterate through files and axes simultaneously
    for i, (log_f, perf_f) in enumerate(zip(log_files, perf_files)):
        ax = axes_flat[i]
        
        # Parse data for this specific pair
        scores = parse_infolog_exactness(log_f)
        lengths = parse_perflog_times(perf_f)
        
        # Calculate cumulative times for this pair
        times = [0]
        for length in lengths:
            times.append(times[-1] + length)

        # 3. Plot on the specific subplot (ax)
        ax.plot(times, scores, linestyle='-', color='#1f77b4', linewidth=2, label='Exactness', alpha=0.8)
        ax.scatter(times, scores, color='#ff7f0e', s=50, label='Data Points', edgecolors='white')
        
        # Set dynamic title based on filename (e.g., 'info-abds.log')
        title_name = log_f.split('/')[-1]
        ax.set_title(title_name, fontsize=12, pad=10)
        ax.set_xlabel('Time', fontsize=10)
        ax.set_ylabel('Exactness', fontsize=10)
        ax.legend(loc='best', frameon=True, fontsize='small')

    # 4. Hide any unused empty subplots
    for j in range(num_plots, len(axes_flat)):
        fig.delaxes(axes_flat[j])

    # Adjust layout to prevent overlap
    plt.tight_layout()
    plt.show()