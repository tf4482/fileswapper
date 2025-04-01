import json
import os
import shutil

from utils_python.colored_text import print_colored
from utils_python.directory_traversal import traverse_and_apply


def load_config():
    """Loads configuration from the config.json file."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(script_dir, "config.json")
    with open(config_path, "r") as f:
        return json.load(f)


if __name__ == "__main__":
    try:
        print("Loading configuration...")
        config = load_config()
        file_pairs = config["file_pairs"]
        print_colored("yellow", "Configuration loaded successfully.")

        def copy_if_exists_and_newer(src, dest_dir):
            """
            Copy the source file to the destination directory if it exists and is newer.

            Args:
                src (str): Path to the source file.
                dest_dir (str): Path to the destination directory.
            """
            dest_file = os.path.join(dest_dir, os.path.basename(src))
            if os.path.exists(dest_file):
                src_mtime = os.path.getmtime(src)
                dest_mtime = os.path.getmtime(dest_file)
                if src_mtime > dest_mtime:
                    shutil.copy2(src, dest_file)
                    print_colored(
                        "green",
                        f"\033[92mFile {src} copied to {dest_file} (newer).\033[0m",
                    )
                else:
                    pass
            else:
                pass

        for pair in file_pairs:
            source_file = pair["source_file"]
            target_dir = pair["target_dir"]
            depth = pair["depth"]
            if depth is None or depth == 0:
                depth = 1
                print_colored(
                    "yellow", f"Depth of {target_dir} not set. Defaulting to 1."
                )
            if not os.path.exists(source_file):
                print_colored("red", f"Source file {source_file} does not exist.")
                continue
            if not os.path.exists(target_dir):
                print_colored("red", f"Target directory {target_dir} does not exist.")
                continue
            print(
                f"Processing pair: Source = {source_file}, Target Directory = {target_dir}"
            )

            # Copy the file to all subdirectories if it exists and is newer
            traverse_and_apply(
                target_dir,
                lambda subdir: copy_if_exists_and_newer(source_file, subdir),
                depth,
            )

            # Additionally, copy the file to the main target directory if it exists and is newer
            copy_if_exists_and_newer(source_file, target_dir)

        print(
            "The files were successfully copied to their respective target directories and subdirectories (only if newer and if they exist)."
        )

        # Wait for a key press before exiting
        input("Press any key to exit")
    except Exception as e:
        print_colored("red", f"An error occurred: {e}")
