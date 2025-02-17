import subprocess
import sys
import os
import logging
from tqdm import tqdm
import xml.etree.ElementTree as ET
import shutil

# Setup logging configuration
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


def parse_path(path):
    """
    Parse a path into partition and relative path components.

    :param path: The path to parse.
    :return: Tuple containing partition and relative path.
    """
    split_index = path[1:].find("/") + 1
    return path[:split_index], path[split_index:],


def remove_from_list(tag, debloat_list_path, remove_path):
    """
    Remove the specified path from the list within the given tag block.

    :param tag: The tag block name to search for in the list.
    :param debloat_list_path: The path to the file containing the list.
    :param remove_path: The path to be removed from the list.
    """
    if input("Remove from list? (y/n)").lower().startswith("y"):
        try:
            with open(debloat_list_path, "r+") as debloat_list:
                # Read the entire contents of the file
                list_contents = debloat_list.readlines()
                # Locate the starting and ending indices of the tag block
                start_index = next(
                    (index for index, line in enumerate(list_contents) if line.strip() == f"{tag} START"),
                    None,
                )
                end_index = next(
                    (index for index, line in enumerate(list_contents) if line.strip() == f"{tag} END"),
                    None,
                )

                # Check if the tag block exists
                if start_index is not None and end_index is not None and start_index < end_index:
                    # Remove the line containing remove_path within the tag block
                    modified_lines = []
                    for line in list_contents[start_index:end_index + 1]:
                        if remove_path not in line:
                            modified_lines.append(line)

                    # Replace the original lines with the modified lines
                    list_contents[start_index:end_index + 1] = modified_lines
                    # Move the file cursor to the beginning and truncate the file
                    debloat_list.seek(0)
                    debloat_list.writelines(list_contents)
                    debloat_list.truncate()
                    print(f"Removed {remove_path} from the {tag} block.")

                else:
                    print(f"Tag block '{tag}' not found or invalid in the list.")

        except FileNotFoundError:
            print(f"Error: File {debloat_list_path} not found.")
        except Exception as e:
            print(f"An unexpected error occurred: {e}")


def delete(paths, target_paths):
    """
    Delete specified paths based on target paths.

    :param paths: List of paths to delete.
    :param target_paths: Dictionary containing target partitions and paths.
    """
    for path in paths:
        partition, relative_path = parse_path(path)
        if partition in target_paths:
            removed = False
            for target_path in target_paths[partition]:
                full_path = join_paths(target_path, relative_path)
                try:
                    if os.path.isdir(full_path):
                        shutil.rmtree(full_path)  # Remove directory and its contents
                    else:
                        os.remove(full_path)
                    removed = True
                except FileNotFoundError:
                    pass
                except Exception as e:
                    logging.error(f"Failed to delete {full_path}: {e}")
            if not removed:
                logging.warning(f"File not found: {relative_path}")


def delete_vintf_tag(path, target_paths, tag_names):
    """
    Remove XML elements from files based on the provided tag names.

    :param path: The path to the file to be processed.
    :param target_paths: Dictionary mapping partitions to target paths.
    :param tag_names: List of tag names to be removed from the XML content.
    """
    partition, relative_path = parse_path(path)

    if partition not in target_paths:
        logging.warning(f"Partition {partition} not found in target paths.")
        return

    delete_tags = False
    error_messages = ""
    for target_path in target_paths[partition]:
        full_path = join_paths(target_path, relative_path)

        if not os.path.exists(full_path):
            logging.error(f"Error: The file {full_path} does not exist.")
            continue

        try:
            with open(full_path, "r") as manifest_file:
                manifest_contents = manifest_file.read()

            original_contents = manifest_contents

            for tag in tag_names:
                tag_approximate = manifest_contents.find(tag)
                if tag_approximate == -1:
                    logging.warning(f"Warning: Tag {tag} not found in {full_path}.")
                    continue

                start_tag = manifest_contents[:tag_approximate].rfind("<hal")
                end_tag = tag_approximate + manifest_contents[tag_approximate:].find("</hal>") + len("</hal>")

                if start_tag == -1 or end_tag == -1:
                    logging.warning(f"Warning: Could not find proper start or end tag for {tag} in {full_path}.")
                    continue

                manifest_contents = manifest_contents[:start_tag] + manifest_contents[end_tag:]

            # Check if content was actually modified
            if manifest_contents == original_contents:
                continue

            # Write updated content back to the file
            with open(full_path, "w") as manifest_file:
                manifest_file.write(manifest_contents)

            delete_tags = True

        except IOError as e:
            error_messages += f"\nError reading or writing file {full_path}: {e}"
        except Exception as e:
            error_messages += f"\nUnexpected error while processing {full_path}: {e}"
        if not delete_tags:
            logging.error(error_messages)


def copy(paths, target_paths, source_path, debloat_list_path):
    """
    Copy files from the source path to the destination paths using `sudo cp -a`.

    This function will:
    - Parse the paths to find the correct partition and relative path.
    - Validate the existence of both source and destination paths.
    - Copy the files while preserving all attributes (like mode, ownership, timestamps).
    - Log every step and show progress with a progress bar.

    :param paths: List of paths to be copied.
    :param target_paths: Dictionary containing target partitions and paths.
    :param source_path: Source directory path where files will be copied from.
    """
    partition_not_found = []

    # Initialize the progress bar
    with tqdm(total=len(paths), desc='Copying files', unit='file') as pbar:
        for path in paths:
            partition, relative_path = parse_path(path)

            # Check if partition exists
            if partition not in target_paths:
                if partition not in partition_not_found:
                    logging.warning(f"Partition {partition} not found in target paths. Skipping...")
                    partition_not_found.append(partition)
                pbar.update(1)
                continue

            # Iterate over each target path
            for target_path in target_paths[partition]:
                src_full_path = join_paths(source_path, relative_path)
                dest_full_path = join_paths(target_path, relative_path)

                # Validation of source file existence
                if not os.path.exists(src_full_path):
                    logging.error(f"Source file does not exist: {src_full_path}. Skipping...")
                    remove_from_list("COPY", debloat_list_path, relative_path)
                    continue

                # Create destination directories if they don't exist
                os.makedirs(os.path.dirname(dest_full_path), exist_ok=True)

                # Execute the copy command
                try:
                    result = subprocess.run(
                        ['sudo', 'cp', '-a', src_full_path, dest_full_path],
                        check=True, text=True, capture_output=True
                    )

                except subprocess.CalledProcessError as e:
                    logging.error(f"Failed to copy {src_full_path} to {dest_full_path}: {e.stderr}")
                except Exception as e:
                    logging.error(f"Unexpected error during copy: {e}")

            pbar.update(1)  # Update progress bar


def fileops(file_path, target_paths, source_path):
    """
    Read and process the contents of a text file to delete specified files.

    :param file_path: Path to the text file to be processed.
    :param target_paths: Dictionary containing target partitions and paths.
    :param source_path: Source path for copying operations.
    """
    try:
        with open(file_path, 'r') as file:
            contents = file.read().replace(" ", "").replace("\t", "")
            contents = '\n'.join([line for line in contents.split('\n') if not line.startswith('#')])
            if contents.find("DELETESTART") != -1 and contents.find("DELETEEND") != -1:
                delete_list = contents[
                              contents.find("DELETESTART") + len("DELETESTART"):contents.find("DELETEEND")].split("\n")
                delete_list = [delete_item for delete_item in delete_list if delete_item.strip()]
                delete(delete_list, target_paths)
            if contents.find("COPYSTART") != -1 and contents.find("COPYEND") != -1:
                copy_list = contents[
                            contents.find("COPYSTART") + len("COPYSTART"):contents.find("COPYEND")].split("\n")
                copy_list = [copy_item for copy_item in copy_list if copy_item.strip()]
                copy(copy_list, target_paths, source_path, file_path)
            if contents.find("VINTFSTART") != -1 and contents.find("VINTFEND") != -1:
                tag_delete_list = contents[
                                  contents.find("VINTFSTART") + len("VINTFSTART"):contents.find("VINTFEND")].split("\n")
                tag_delete_list = [tag_delete_item for tag_delete_item in tag_delete_list if tag_delete_item.strip()]
                delete_vintf_tag("/vendor/etc/vintf/manifest.xml", target_paths, tag_delete_list)
    except IOError as e:
        logging.error(f"Error processing {file_path}: {e}")


if __name__ == "__main__":
    # Check for correct number of arguments
    if len(sys.argv) < 4:
        print("""
Usage: python fileops.py <file_path> <source_path> [--partition target_partition] [target_paths ...]

Manages files based on the contents of a text file.

Arguments:
  file_path             Path to the text file containing paths to be deleted.
  source_path              Source path for copying files.
  --partition partition Specify a partition to target (e.g., --system).
  target_paths          Paths to be targeted for deletion.

Example:
  python fileops.py tasks.txt /source/path --system /c1s/system /c2s/system --vendor /c1s/vendor /c2s/vendor
    - Manages files listed in 'tasks.txt' within specified partitions (/system/app and /system/priv-app).
""")
        sys.exit(1)

    file_path = sys.argv[1]
    source_path = sys.argv[2]

    target_paths = {}
    current_partition = ""
    for index in range(3, len(sys.argv)):
        if sys.argv[index].startswith("--"):
            current_partition = "/" + sys.argv[index][2:]
        else:
            if current_partition not in target_paths:
                target_paths[current_partition] = []
            target_paths[current_partition].append(sys.argv[index])

    fileops(file_path, target_paths, source_path)
