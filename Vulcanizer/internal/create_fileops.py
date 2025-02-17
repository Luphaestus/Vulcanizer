import sys
import subprocess
import logging
import os
from tqdm import tqdm

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


def read_exclusion_files(exclude_files):
    """
    Read exclusion files and return a set of paths to be excluded.

    :param exclude_files: List of paths to exclusion text files.
    :return: Set of paths to be excluded.
    """
    excluded_paths = {'DELETE': [], 'COPY': []}
    exclude_type = "DELETE"
    for exclude_file in exclude_files:
        if not os.path.exists(exclude_file):
            logging.warning(f"Exclusion file not found: {exclude_file}")
            continue

        with open(exclude_file, 'r') as f:
            for line in f:
                path = line.strip()
                if path == "DELETE START":
                    exclude_type = "DELETE"
                    continue
                elif path == "COPY START":
                    exclude_type = "COPY"
                    continue
                if " END" in path:
                    exclude_type = ""
                if exclude_type == "":
                    continue
                excluded_paths[exclude_type].append(path)
    return excluded_paths


def diff_directories(output_file, exclude_files, *directories):
    """
    Run sudo diff -rq on multiple pairs of directories and save the output to a file.
    Paths listed in exclusion files are excluded from the comparison.

    :param output_file: Path to the file where the results will be saved.
    :param exclude_files: List of paths to text files containing paths to be excluded from comparison.
    :param directories: Variable number of directory pairs to compare. Each pair is given as
                        a tuple (partition_name, dir1, dir2) where dir1 and dir2 are paths
                        to the directories to compare, and partition_name is a label for the pair.
    """
    excluded_paths = read_exclusion_files(exclude_files)
    files_to_copy = {}
    files_to_delete = {}

    total_comparisons = len(directories)

    with tqdm(total=total_comparisons, unit='comparison', desc='Comparing directories') as pbar:
        for info in directories:
            partition_name, dir1, dir2 = info
            files_to_copy[partition_name] = []
            files_to_delete[partition_name] = []
            try:
                diff = subprocess.run(['sudo', 'diff', '-rq', dir1, dir2], stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE,
                                      text=True)
            except subprocess.CalledProcessError as e:
                logging.error(f"Failed to run diff -rq: {e}")
                exit(1)

            for file in diff.stdout.split("\n"):
                if file == "": continue
                if file.startswith("Only in"):
                    path = file[8:].replace(": ", "/").replace("//", "/")
                    if path.startswith(dir1):
                        relative_path = "/" + partition_name + ("/" if dir1[-1] == "/" else "") + path[len(dir1):]
                        if relative_path not in excluded_paths["DELETE"]:
                            files_to_delete[partition_name].append(relative_path)
                    else:
                        relative_path = "/" + partition_name + ("/" if dir2[-1] == "/" else "") + path[len(dir2):]
                        if relative_path not in excluded_paths["COPY"]:
                            files_to_copy[partition_name].append(relative_path)
                else:
                    path = file[6 + len(dir1):file.find(" and ")]
                    path = "/" + partition_name + ("" if path[0] == "/" else "/") + path
                    if path not in excluded_paths["COPY"]:
                        files_to_copy[partition_name].append(path)

            pbar.update(1)

    # Prepare result string
    result_string = "DELETE START\n"
    for partition in files_to_delete.keys():
        result_string += "\t#" + partition + "\n"
        for file in files_to_delete[partition]:
            result_string += "\t\t" + file + "\n"
    result_string += "DELETE END\nCOPY START\n"
    for partition in files_to_copy.keys():
        result_string += "\t#" + partition + "\n"
        for file in files_to_copy[partition]:
            result_string += "\t\t" + file + "\n"
    result_string += "COPY END"

    # Save results to the output file
    with open(output_file, 'w') as f:
        f.write(result_string)

    logging.info(f"Results saved to {output_file}")


if __name__ == "__main__":
    args = sys.argv[1:]
    exclude_files = []
    if '--exclude' in args:
        exclude_start = args.index('--exclude')
        exclude_end = -1
        for index in range(exclude_start + 1, len(args)):
            if args[index].startswith("--"):
                exclude_end = index
                break
        exclude_files = args[exclude_start + 1:exclude_end]
        args = args[exclude_end:]
    else:
        args_start = -1
        for index in range(0, len(args)):
            if args[index].startswith("--"):
                args_start = index
                break
        args = args[args_start:]

    if len(args) < 3 or len(args) % 3 != 0:
        print("""
Usage: python diff_directories.py <output_file> [--exclude <exclude_file1> <exclude_file2> ...] <partition1> <dir1a> <dir1b> [<partition2> <dir2a> <dir2b> ...]

Compares multiple pairs of directories and outputs the differences to a file. Each pair is given as
a partition name followed by two directory paths to compare. Paths listed in exclusion files are excluded
from the comparison.

Arguments:
  output_file      Path to the file where results will be saved.
  --exclude        Optional flag to specify one or more exclusion files. Each file should contain paths to be excluded.
  partitionX       Name of the partition or label for the comparison.
  dirXa            Path to the first directory of the Xth comparison.
  dirXb            Path to the second directory of the Xth comparison.

Example:
  python diff_directories.py results.txt --exclude exclude1.txt exclude2.txt part1 /path/to/dir1a /path/to/dir1b part2 /path/to/dir2a /path/to/dir2b
    - Compares /path/to/dir1a with /path/to/dir1b, and /path/to/dir2a with /path/to/dir2b, saving results to results.txt.
    - Excludes paths listed in exclude1.txt and exclude2.txt from the comparison.
""")
        sys.exit(1)

    output_file = sys.argv[1]

    directories = []
    for i in range(0, len(args) - 2, 3):
        partition_name = args[i]
        dir1 = args[i + 1]
        dir2 = args[i + 2]
        directories.append((partition_name.replace("--", ""), dir1, dir2))

    diff_directories(output_file, exclude_files, *directories)
