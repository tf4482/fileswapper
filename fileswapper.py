import os
import json
import platform


from yapl_python.robocopy_update import robocopy_update
from yapl_python.rsync_to_subdirs import rsync_to_subdirs
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
        source_file = config["source_file"]
        target_dir = config["target_dir"]

        # Choose the correct copy function based on the operating system
        system = platform.system()
        copy_function = robocopy_update if system == "Windows" else rsync_to_subdirs

        # Copy the file to all subdirectories
        traverse_and_apply(target_dir, lambda subdir: copy_function(source_file, subdir))

        # Additionally, copy the file to the main target directory
        copy_function(source_file, target_dir)

        print(f"The file was successfully copied to '{target_dir}' and all its subdirectories (only if newer).")
    except Exception as e:
        print(f"An error occurred: {e}")
