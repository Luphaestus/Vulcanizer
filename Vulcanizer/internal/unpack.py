import os
import shutil
import subprocess
import sys
import logging
from tqdm import tqdm


def setup_logging():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


def unpack(image_path, destination_path):
    """
    Convert an image to a standard directory

    :param image_path: Path to the image file (.img) to be mounted.
    :param destination_path: Destination path where the contents of the image will be copied.
    """

    setup_logging()
    mount_point = '/mnt/unpack_mnt/'

    if not os.path.exists(mount_point):
        os.makedirs(mount_point)

    logging.info("Checking if image is already mounted...")
    is_mounted = subprocess.call(['mountpoint', '-q', mount_point])

    if is_mounted != 0:
        try:
            logging.info(f"Mounting image {image_path} to {mount_point}...")
            subprocess.check_call(['sudo', 'mount', '-o', 'loop', image_path, mount_point])
            logging.info(f"Image {image_path} mounted successfully to {mount_point}.")
        except subprocess.CalledProcessError as e:
            logging.error(f"Failed to mount image {image_path}. Error: {e}")
            return

    try:
        total_items = sum([len(files) for r, d, files in os.walk(mount_point)])
        with tqdm(total=total_items, desc="Copying files", unit="file") as pbar:
            for root, dirs, files in os.walk(mount_point):
                for dir in dirs:
                    src_dir = os.path.join(root, dir)
                    dst_dir = os.path.join(destination_path, os.path.relpath(src_dir, mount_point))
                    os.makedirs(dst_dir, exist_ok=True)
                    if os.path.islink(src_dir):
                        link_target = os.readlink(src_dir)
                        dst_link = os.path.join(destination_path, os.path.relpath(src_dir, mount_point))
                        if not os.path.exists(dst_link):
                            os.symlink(link_target, dst_link)
                for file in files:
                    src_file = os.path.join(root, file)
                    dst_file = os.path.join(destination_path, os.path.relpath(src_file, mount_point))
                    if os.path.islink(src_file):
                        link_target = os.readlink(src_file)
                        if not os.path.exists(dst_file):
                            os.symlink(link_target, dst_file)
                    else:
                        shutil.copy2(src_file, dst_file)
                    pbar.update(1)
        logging.info(f"Contents of {image_path} copied to {destination_path} successfully.")
    except shutil.Error as e:
        logging.error(f"Failed to copy contents from {image_path} to {destination_path}. Error: {e}")
    finally:
        logging.info(f"Unmounting {mount_point}...")
        subprocess.call(['sudo', 'umount', mount_point])


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("""
Usage: python unpack.py <image_path> <destination_path>

Convert an image file to a standard directory.

Arguments:
  image_path         Path to the image file to be unpacked.
  destination_path   Destination path where the contents of the image will be copied.

Example:
  python unpack.py vendor.img vendor
    - Unpacks 'vendor.img' to 'vendor' directory.
""")
        sys.exit(1)

    image_path = sys.argv[1]
    destination_path = sys.argv[2]

    unpack(image_path, destination_path)
