import os
import hashlib
import shutil
import subprocess
import sys
import logging
from tqdm import tqdm
import shutil


def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


def join_paths(root, path):
    """
    Join root and path, ensuring the resulting path is correct even if path is absolute.

    :param root: The root directory.
    :param path: The path to join with the root.
    :return: The joined path.
    """
    path = path[1:] if path[0] == "/" else path
    return os.path.join(root, path)


def get_last_directory(path):
    """
    Get the last directory component of a given path.

    :param path: The original path.
    :return: The name of the last directory in the path.
    """
    normalized_path = os.path.normpath(path)
    last_dir = os.path.basename(normalized_path)
    return last_dir


def copy_files(paths, source_root, destination_root):
    """
    Copy files and directories from source_root to destination_root.

    :param paths: List of paths relative to source_root.
    :param source_root: Root directory where paths are located.
    :param destination_root: Root directory where paths should be copied.
    """
    with tqdm(total=len(paths), desc="Copying " + get_last_directory(destination_root), unit="file", ) as pbar:
        for path in paths:
            source_path = join_paths(source_root, path)
            destination_path = join_paths(destination_root, path)

            os.makedirs(os.path.dirname(destination_path), exist_ok=True)

            if os.path.exists(destination_path):
                logging.warning(f"Warning: {destination_path} already exists. Skipping...")
                continue

            try:
                subprocess.run(['sudo', 'cp', '-a', source_path, destination_path], check=True)
            except Exception as e:
                logging.error(f"Error copying {source_path} to {destination_path}: {e}")
            pbar.update(1)


def calculate_checksum(file_path, algorithm='md5'):
    """
    Calculate the checksum (hash) of a file using hashlib.

    If the file is a symbolic link, return the target of the symlink.

    :param file_path: Path to the file.
    :param algorithm: Hash algorithm to use ('md5', 'sha1', 'sha256', etc.).
                      Defaults to 'md5'.
    :return: Hexadecimal digest (checksum) of the file or the symlink target,
             or None if the file is not found or symlink resolution fails.
    """
    if os.path.islink(file_path):
        target_path = os.readlink(file_path)
        return target_path
    if os.path.isdir(file_path):
        return file_path
    hash_func = getattr(hashlib, algorithm)()
    total_size = os.path.getsize(file_path)
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            hash_func.update(chunk)
    return hash_func.hexdigest()


def get_directory_map(directory_path, start_directory):
    """
    Create a list of every file and empty directory path within the given directory.

    :param directory_path: Path to the directory to map.
    :param start_directory: Starting directory to calculate relative paths.
    :return: List of all file and directory paths within the directory.
    """
    if not os.path.exists(directory_path):
        raise FileNotFoundError(f"The directory '{directory_path}' does not exist.")
    if not os.path.isdir(directory_path):
        raise NotADirectoryError(f"The path '{directory_path}' is not a directory.")

    paths = []
    for root, dirs, files in os.walk(directory_path):
        for directory in dirs:
            dir_path = join_paths(root, directory)
            if not os.listdir(dir_path):
                paths.append(dir_path[dir_path.find(start_directory) + len(start_directory):])
        for file in files:
            file_path = join_paths(root, file)
            paths.append(file_path[file_path.find(start_directory) + len(start_directory):])

    return paths


def compare_directory_maps(*directory_maps):
    """
    Compare multiple directory maps and return common and unique items.

    :param directory_maps: Multiple lists of directory maps (file and directory paths).
    :return: A tuple containing:
        - List of common items.
        - List of sets for each directory map's unique items.
    """
    if not directory_maps:
        raise ValueError("At least one directory map must be provided.")

    sets = [set(directory_map) for directory_map in directory_maps]
    common_items = set.intersection(*sets)
    unique_items = [directory_set - common_items for directory_set in sets]

    return list(common_items), unique_items


def compare_checksums(common_paths, *source_directories):
    """
    Compare checksums of common paths across multiple source directories.

    :param common_paths: List of common file paths.
    :param source_directories: Source directories to compare.
    :return: A tuple containing:
        - List of common checksums.
        - List of unique checksums.
    """
    common_checksums = []
    unique_checksums = []

    with tqdm(total=len(common_paths), desc="Comparing checksums", unit="file", ) as pbar:
        for path in common_paths:
            checksum_comparison = {}
            for root in source_directories:
                checksum = calculate_checksum(join_paths(root, path))
                if checksum in checksum_comparison:
                    checksum_comparison[checksum].append(root)
                else:
                    checksum_comparison[checksum] = [root]
            if len(checksum_comparison) == 1:
                common_checksums.append(path)
            else:
                unique_checksums.append(path)
            pbar.update(1)
    return common_checksums, unique_checksums


def make_common(common_directory, *directories):
    """
    Separate common and unique files from multiple directories to save space.

    :param common_directory: Directory where common files will be stored.
    :param directories: Pairs of source and unique output directories.
    :return: A dictionary containing:
        - Directory map for each model.
        - List of common files.
        - List of unique files.
    """
    logging.info("Making common")
    try:
        models = {}
        for model_directories in directories:
            name = get_last_directory(model_directories[0])
            models[name] = {
                "source_directory": model_directories[0],
                "unique_directory": model_directories[1]
            }

        for model in models.keys():
            models[model]["directory_map"] = get_directory_map(models[model]["source_directory"], model)

        common_paths, unique_paths = compare_directory_maps(*(value["directory_map"] for value in models.values()))
        for (key, value), unique_set in zip(models.items(), unique_paths):
            value["unique_paths"] = list(unique_set)

        common_checksums, unique_checksums = compare_checksums(common_paths, *(value["source_directory"] for value in
                                                                               models.values()))
        for model in models.keys():
            models[model]["unique_paths"].extend(unique_checksums)
            copy_files(models[model]["unique_paths"], models[model]["source_directory"],
                       models[model]["unique_directory"])
        copy_files(common_checksums, models[list(models.keys())[0]]["source_directory"], common_directory)

        logging.info("Common and unique files separated successfully.")
        return models
    except PermissionError:
        logging.error("Permission Error: Make sure to run the script with sudo / administrator privileges")
        sys.exit(1)


if __name__ == '__main__':
    setup_logging()
    args = sys.argv[1:]
    if len(args) < 3 or len(args) % 2 == 0:
        logging.error("Invalid arguments")
        print("""
Usage: python make_common.py <common_output_directory> [<source_directory> <unique_output_directory>]...

Arguments:
  common_output_directory    Directory where common files will be outputted.
  source_directory           Source directory containing files to process.
  unique_output_directory    Output directory specific to the source directory.

Examples:
  python make_common.py common/ c1s/ c1su/
    - Processes files from 'c1s/' and outputs unique files to 'c1su/' within 'common/'.

  python make_common.py common/ c2s/ c2su/ c3s/ c3su/
    - Processes files from 'c2s/' and 'c3s/' and outputs unique files to 'c2su/' and 'c3su/' within 'common/' respectively.
""")
        sys.exit(1)

    common = args[0]
    arguments = []
    for index in range(1, len(args), 2):
        arguments.append([args[index], args[index + 1]])

    make_common(common, *arguments)
