def split_file_with_header(input_file, output_prefix, n):
    """
    Splits a file into n parts with header preserved in each file.
    """
    with open(input_file, 'r') as f:
        # Read header
        header = f.readline()
        total_lines = sum(1 for _ in f)  # Count remaining lines
        f.seek(0)  # Rewind to beginning
        
        lines_per_file = (total_lines + n - 1) // n
        
        for i in range(1, n + 1):
            output_file = f"{output_prefix}-{i}.tsv"
            with open(output_file, 'w') as out_f:
                # Write header
                out_f.write(header)
                # Skip header for subsequent reads
                if i == 1:
                    f.readline()  # skip header in input file
                # Write lines_per_file lines to each output file
                for _ in range(lines_per_file):
                    line = f.readline()
                    if not line:
                        break
                    out_f.write(line)
    
    print(f"Successfully split {input_file} into {n} files with prefix {output_prefix}")

if __name__ == "__main__":
    input_file = "venv/etc/testcase/_1m.tsv"
    output_prefix = "venv/etc/testcase/100k"
    n = 10
    split_file_with_header(input_file, output_prefix, n)