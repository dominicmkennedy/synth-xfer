from stitch_core import compress
from pathlib import Path

""" gather .lam files """

def get_file_contents(folder_path):
    # Create a Path object for the directory
    directory = Path(folder_path)
    
    # Use rglob('*') to find all files recursively, or glob('*') for just the top level
    # We filter with is_file() to skip subfolders
    content_list = [file.read_text(encoding='utf-8') for file in directory.glob('*') if file.is_file()]
    
    return content_list

programs = get_file_contents("corpus/lam/")
print(f'Read {len(programs)} files')

# arity is how many args the function takes
res = compress(programs, iterations=3, max_arity=3)

out_file = "abstractions.txt"
with open(out_file, "w") as file:
    for a in res.abstractions:
        file.write(str(a))
        file.write('\n')

print(f"wrote to file {out_file}")