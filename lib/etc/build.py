import sys
import json
import os
import shutil
from os import path


if __name__ == "__main__":
    with open(sys.argv[1], "r") as f:
        etc_data = json.load(f)
    
    output_dir = sys.argv[2]

    # Create the output directory, else the derivation will fail
    os.mkdir(output_dir)

    for file in etc_data:
        target_file = path.join(output_dir, file["target"])

        # Create the parent directory if it doesn't exist
        target_dir = path.dirname(target_file)
        os.makedirs(target_dir, exist_ok=True)

        if file["mode"] == "symlink":
            # Symlink source to target, then we are done
            os.symlink(file["source"], target_file)
            continue

        # Copy the file
        shutil.copy2(file["source"], target_file, follow_symlinks=True)
        os.chmod(target_file, int(file['mode'], 8))
