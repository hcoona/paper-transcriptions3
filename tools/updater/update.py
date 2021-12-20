"""Tools update archive folders for generated LaTeX files.
"""

import difflib
import logging
import shutil
import sys
from pathlib import Path

EXCLUDE_FOLDERS_NAMES = ['archive', 'common', 'tools']
PDF_FILENAME = "main.pdf"
CHECKSUM_FILENAME = "main.sha512"


def _parse_hashfile(path):
    """Parse sha512sum generated file."""
    with path.open("r", encoding="utf8") as fp:
        return fp.readlines()


def main():
    """Copy built PDF & checksum files from bazel-bin to archive folder.
    """
    logger = logging.getLogger(__name__)
    src_root_dir = Path('./bazel-bin')
    dst_root_dir = Path('./archive')

    srcs_dirs = [
        d for d in src_root_dir.iterdir()
        if d.is_dir() and d.name not in EXCLUDE_FOLDERS_NAMES
    ]
    for d in srcs_dirs:
        logger.info("Processing %s", d.name)

        src_pdf = d / PDF_FILENAME
        dst_pdf = dst_root_dir / (d.name + ".pdf")

        src_checksum = d / CHECKSUM_FILENAME
        if not src_checksum.exists():
            logging.error('Checksum file %s not generated.',
                          src_checksum.resolve())
            return 11

        dst_checksum = dst_root_dir / (d.name + ".sha512")

        diff = []
        if dst_checksum.exists():
            src_checksum_content = _parse_hashfile(src_checksum)
            dst_checksum_content = _parse_hashfile(dst_checksum)
            # opt out the generated PDF file checksum.
            diff = list(
                difflib.unified_diff(src_checksum_content[1:],
                                    dst_checksum_content[1:]))


        if dst_checksum.exists() and len(diff) == 0:
            logging.info('Checksum of %s and %s are same.',
                         src_checksum.resolve(), dst_checksum.resolve())
        else:
            logging.warning('Checksum of %s and %s are not same.',
                            src_checksum.resolve(), dst_checksum.resolve())
            shutil.copyfile(src_pdf.resolve(),
                            dst_pdf.resolve(),
                            follow_symlinks=True)
            shutil.copyfile(src_checksum.resolve(),
                            dst_checksum.resolve(),
                            follow_symlinks=True)
            logging.info('PDF & checksum files for %s updated.', d.name)

    return 0


if __name__ == '__main__':
    logging.basicConfig(
        format='%(asctime)s %(name)s %(levelname)s - %(message)s',
        datefmt="%Y-%m-%dT%H:%M:%S%z",
        stream=sys.stderr,
        level=logging.DEBUG)
    code = main()
    sys.exit(code)
