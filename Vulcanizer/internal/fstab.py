import sys


def remove_avb(contents):
    """
    Remove all occurrences of ",avb" and the following segment until the next comma or newline.

    :param contents: The content of the fstab file.
    :return: The modified content with ",avb" segments removed.
    """
    while "avb" in contents:
        start = contents.find(",avb")
        end = start + (contents[start + 1:].find(",") if contents[start + 1:].find(",") < contents[start + 1:].find(
            "\n") else contents[start + 1:].find("\n")) + 1
        contents = contents[:start] + contents[end:]
    return contents


def remove_file_encryption(contents):
    """
    Remove all occurrences of "fileencryption=ice," from the contents.

    :param contents: The content of the fstab file.
    :return: The modified content with "fileencryption=ice," removed.
    """
    return contents.replace("fileencryption=ice,", "")


def patch_fstab(path, remove_encryption):
    """
    Patch the fstab file to remove AVB and optionally file encryption.

    :param path: Path to the fstab file.
    :param remove_encryption: Boolean or string to indicate if file encryption should be removed.
    """
    with open(path, "r") as fstab_file:
        fstab_contents = fstab_file.read()

    fstab_contents = remove_avb(fstab_contents)

    if remove_encryption.lower()[0] in ["y", "t"]:
        fstab_contents = remove_file_encryption(fstab_contents)

    with open(path, "w") as fstab_file:
        fstab_file.write(fstab_contents)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("""
Usage: python fstab.py <fstab_path> <remove_encryption>

Patch an fstab file to remove AVB and optionally file encryption.

Arguments:
  fstab_path          Path to the fstab file to be patched.
  remove_encryption   Whether to remove file encryption (true/false).

Example:
  python patch_fstab.py /path/to/fstab true
    - Patches the fstab file at '/path/to/fstab' and removes file encryption.
""")
        sys.exit(1)

    patch_fstab(sys.argv[1], sys.argv[2])
