# FileSwapper 📂🔄

FileSwapper is a Python-based utility for managing and automating file operations like copying files to specific directories and subdirectories based on configuration. It supports features like filtering, directory traversal, and colored console output for better user experience.

## Features ✨

- **Configuration-Driven** 🛠️: Define file operations in a JSON configuration file.
- **Selective Copying** ✅: Copy files only if they are newer than the existing ones.
- **Directory Traversal** 📂: Traverse directories up to a specified depth.
- **Colored Output** 🎨: Display messages in different colors for better readability.
- **File Selection** 🔍: Interactive file selection from directories.
- **Utility Functions** 🔧: Includes reusable utilities for file operations.

## Installation 🚀

1. Clone the repository:
   ```bash
   git clone https://github.com/tf4482/fileswapper.git
   cd fileswapper
   ```

2. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Usage 🖥️

1. Create a configuration file based on `example.config.json`:
   ```json
   {
       "file_pairs": [
           {
               "source_file": "path/to/source/file.txt",
               "target_dir": "path/to/target/directory",
               "depth": 2
           }
       ]
   }
   ```

2. Run the script:
   ```bash
   python fileswapper.py
   ```

3. Follow the on-screen instructions to manage your file operations.

## Project Structure 📁

```
fileswapper/
├── utils_python/          # Utility modules for file operations
│   ├── colored_text.py    # Colored console output
│   ├── convert_to_string.py # Data conversion utilities
│   ├── copy_files.py      # File copying logic
│   ├── directory_traversal.py # Directory traversal logic
│   ├── list_files.py      # File listing utility
│   ├── select_file.py     # Interactive file selection
│   └── __init__.py        # Package initializer
├── fileswapper.py         # Main script
├── example.config.json    # Example configuration file
├── .gitignore             # Git ignore rules
├── README.md              # Project documentation
└── LICENSE                # License file
```

## Contributing 🤝

Contributions are welcome! Feel free to open issues or submit pull requests to improve this project.

## License 📜

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---
