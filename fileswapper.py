import os
import json
import shutil

from yapl_python.directory_traversal import traverse_and_apply


def load_config():
    """Loads configuration from the config.json file."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(script_dir, "config.json")
    with open(config_path, "r") as f:
        return json.load(f)

if __name__ == "__main__":
    try:
        config = load_config()
        file_pairs = config["file_pairs"]

        def copy_if_exists_and_newer(src, dest_dir):
            dest_file = os.path.join(dest_dir, os.path.basename(src))
            if os.path.exists(dest_file):
                src_mtime = os.path.getmtime(src)
                dest_mtime = os.path.getmtime(dest_file)
                if src_mtime > dest_mtime:
                    shutil.copy2(src, dest_file)

        for pair in file_pairs:
            source_file = pair["source_file"]
            target_dir = pair["target_dir"]

            # Copy the file to all subdirectories if it exists and is newer
            traverse_and_apply(target_dir, lambda subdir: copy_if_exists_and_newer(source_file, subdir))

            # Additionally, copy the file to the main target directory if it exists and is newer
            copy_if_exists_and_newer(source_file, target_dir)

        print("The files were successfully copied to their respective target directories and subdirectories (only if newer and if they exist).")
    except Exception as e:
        print(f"An error occurred: {e}")
