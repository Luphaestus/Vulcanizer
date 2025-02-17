import sys
import os
import subprocess
import logging
from tqdm import tqdm


class StringLogHandler(logging.Handler):
    def __init__(self):
        super().__init__()
        self.log_string = ""

    def emit(self, record):
        log_entry = self.format(record)
        if record.levelno >= logging.ERROR:
            print(log_entry)
        else:
            self.log_string += log_entry + '\n'

    def get_log(self):
        return self.log_string


log_handler = StringLogHandler()
log_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
log_handler.setFormatter(log_formatter)
logging.getLogger().addHandler(log_handler)
logging.getLogger().setLevel(logging.INFO)


def merge_folders(source_folders, destination_folder):
    """
    Merge contents of source folders into the destination folder.

    :param source_folders: List of source folder paths.
    :param destination_folder: Path to the destination folder.
    """
    if not os.path.exists(destination_folder):
        os.makedirs(destination_folder)

    total_files = 0
    for source_folder in source_folders:
        for _, _, files in os.walk(source_folder):
            total_files += len(files)

    with tqdm(total=total_files, unit='file', desc='Merging folders') as pbar:
        for source_folder in source_folders:
            for root, dirs, files in os.walk(source_folder):
                rel_path = os.path.relpath(root, source_folder)
                destination_path = os.path.join(destination_folder, rel_path)
                if not os.path.exists(destination_path):
                    os.makedirs(destination_path)
                for file in files:
                    source_file = os.path.join(root, file)
                    destination_file = os.path.join(destination_path, file)
                    if os.path.exists(destination_file):
                        logging.warning(f"File already exists - file will be overwritten: {destination_file}")
                    try:
                        subprocess.run(['sudo', 'cp', '-a', source_file, destination_file], check=True)
                        #logging.info(f"Copied {source_file} to {destination_file}")
                    except Exception as e:
                        logging.error(f"Failed to copy {source_file} to {destination_file}: {e}")
                    pbar.update(1)
    print(log_handler.get_log())


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("""
Usage: python merge_folders.py <destination_folder> <source_folder1> [source_folder2] ...

Merges multiple source folders into a destination folder.

Arguments:
  destination_folder           Path to the destination folder where files will be merged.
  source_folder1           Path to the first source folder.
  source_folder2           (Optional) Path to additional source folders.

Example:
  python merge_folders.py /destination_folder /source_folder1 /source_folder2 /source_folder3
    - Merges contents of /source_folder1, /source_folder2, and /source_folder3 into /destination_folder.
""")
        sys.exit(1)

    destination_folder = sys.argv[1]
    source_folders = sys.argv[2:]

    merge_folders(source_folders, destination_folder)
