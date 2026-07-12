#!/usr/bin/env python3
"""
print_tree.py

Generate and print a directory tree structure for a given folder path,
similar to the `tree` command — with interactive prompts for anything
not supplied on the command line, and support for saving/updating a
structure file every time you run it.

Usage (all flags optional — you'll be prompted for anything missing):
    python print_tree.py
    python print_tree.py /path/to/folder
    python print_tree.py /path/to/folder --ignore node_modules .git venv
    python print_tree.py /path/to/folder --ext .dart .yaml --max-depth 3
    python print_tree.py /path/to/folder -o structure.txt

Run it again later on the same folder with the same -o file and it will
UPDATE that file with the latest structure (old content is replaced,
plus a timestamp so you can see when it last changed).

You can also create a zip archive of the folder (or specific
sub-folders inside it, comma separated) — either interactively when
prompted, or directly via flags:
    python print_tree.py /path/to/lib --zip
    python print_tree.py /path/to/lib --zip-folders reader,settings
    python print_tree.py /path/to/lib --zip-folders reader,settings --zip-output my_code.zip
"""

import argparse
import os
import sys
import zipfile
from datetime import datetime

# Directories/files to skip by default (common noise)
DEFAULT_IGNORE = {
    ".git", ".svn", ".hg", "__pycache__", ".DS_Store",
    "node_modules", ".idea", ".vscode", "build", ".dart_tool",
    ".venv", "venv", "env",
}


def build_tree(root_path, ignore_set, show_files=True, max_depth=None, extensions=None):
    """
    Returns (lines, folder_count, file_count) for the tree rooted at root_path.
    extensions: optional set of lowercase extensions (e.g. {'.dart', '.yaml'})
                to include; if None, all files are included.
    """
    lines = []
    folder_count = 0
    file_count = 0

    root_path = os.path.abspath(root_path)
    root_name = os.path.basename(root_path.rstrip(os.sep)) or root_path
    lines.append(f"{root_name}/")

    def matches_ext(filename):
        if not extensions:
            return True
        return os.path.splitext(filename)[1].lower() in extensions

    def walk(current_path, prefix, depth):
        nonlocal folder_count, file_count

        if max_depth is not None and depth > max_depth:
            return

        try:
            raw_entries = os.listdir(current_path)
        except PermissionError:
            lines.append(f"{prefix}└── [Permission Denied]")
            return

        entries = [e for e in raw_entries if e not in ignore_set]

        filtered = []
        for e in entries:
            full = os.path.join(current_path, e)
            if os.path.isdir(full):
                filtered.append(e)
            else:
                if show_files and matches_ext(e):
                    filtered.append(e)

        filtered.sort(key=lambda e: (not os.path.isdir(os.path.join(current_path, e)), e.lower()))

        count = len(filtered)
        for index, entry in enumerate(filtered):
            full_path = os.path.join(current_path, entry)
            is_last = index == count - 1
            connector = "└── " if is_last else "├── "
            is_dir = os.path.isdir(full_path)

            if is_dir:
                folder_count += 1
                lines.append(f"{prefix}{connector}{entry}/")
                extension_prefix = "    " if is_last else "│   "
                walk(full_path, prefix + extension_prefix, depth + 1)
            else:
                file_count += 1
                lines.append(f"{prefix}{connector}{entry}")

    walk(root_path, "", 1)
    return lines, folder_count, file_count


def create_zip(base_path, subfolders, zip_output, ignore_set):
    """
    Create a zip archive.
    - base_path: the parent folder (e.g. /path/to/lib)
    - subfolders: list of subfolder names relative to base_path to include,
                  or None/empty to zip the entire base_path.
    - ignore_set: names to skip while walking (same as tree ignore list).
    Returns the absolute path of the created zip file.
    """
    base_path = os.path.abspath(base_path)

    if not zip_output:
        default_name = os.path.basename(base_path.rstrip(os.sep)) or "archive"
        zip_output = f"{default_name}.zip"
    if not zip_output.lower().endswith(".zip"):
        zip_output += ".zip"

    if subfolders:
        roots_to_zip = []
        for name in subfolders:
            name = name.strip()
            if not name:
                continue
            full = os.path.join(base_path, name)
            if not os.path.isdir(full):
                print(f"Warning: '{full}' not found or not a folder — skipping.", file=sys.stderr)
                continue
            roots_to_zip.append((name, full))
    else:
        roots_to_zip = [(os.path.basename(base_path.rstrip(os.sep)), base_path)]

    if not roots_to_zip:
        print("Error: nothing valid to zip.", file=sys.stderr)
        return None

    with zipfile.ZipFile(zip_output, "w", zipfile.ZIP_DEFLATED) as zf:
        for arc_root_name, folder_path in roots_to_zip:
            for current_dir, dirnames, filenames in os.walk(folder_path):
                dirnames[:] = [d for d in dirnames if d not in ignore_set]
                for fname in filenames:
                    if fname in ignore_set:
                        continue
                    full_file = os.path.join(current_dir, fname)
                    rel_inside_root = os.path.relpath(full_file, folder_path)
                    arcname = os.path.join(arc_root_name, rel_inside_root)
                    zf.write(full_file, arcname)

    return os.path.abspath(zip_output)


def prompt_yes_no(question, default=False):
    suffix = " [y/N]: " if not default else " [Y/n]: "
    ans = input(question + suffix).strip().lower()
    if not ans:
        return default
    return ans in ("y", "yes")


def prompt_for_missing_args(args):
    """Interactively fill in any argument the user didn't pass on the CLI."""

    if not args.path:
        args.path = input("Enter the folder path: ").strip().strip('"').strip("'")

    if not args.ignore_asked:
        extra_ignore = input(
            "Any additional folders/files to ignore? (space separated, or press Enter to skip): "
        ).strip()
        if extra_ignore:
            args.ignore = extra_ignore.split()

    if args.max_depth is None:
        depth_input = input("Max depth to show? (press Enter for unlimited): ").strip()
        if depth_input:
            try:
                args.max_depth = int(depth_input)
            except ValueError:
                print("Invalid number, using unlimited depth.")

    if not args.dirs_only_asked:
        args.dirs_only = prompt_yes_no("Show folders only (no files)?", default=False)

    if not args.ext_asked and not args.dirs_only:
        ext_input = input(
            "Filter by file extension(s)? e.g. .dart .yaml (press Enter to include all files): "
        ).strip()
        if ext_input:
            args.ext = ext_input.split()

    if not args.output_asked:
        out_input = input(
            "Save/update output to a text file? Enter a filename or press Enter to skip: "
        ).strip()
        if out_input:
            args.output = out_input

    if not args.zip_asked:
        args.zip = prompt_yes_no("Create a zip file of this folder?", default=False)
        if args.zip and not args.zip_folders:
            folders_input = input(
                "Which sub-folders to zip? (comma separated, press Enter to zip the whole "
                f"'{os.path.basename(args.path.rstrip(os.sep))}' folder): "
            ).strip()
            if folders_input:
                args.zip_folders = folders_input
        if args.zip and not args.zip_output:
            zip_name_input = input(
                "Zip file name? (press Enter for default name): "
            ).strip()
            if zip_name_input:
                args.zip_output = zip_name_input

    return args


def main():
    parser = argparse.ArgumentParser(
        description="Print (and optionally save/update) the directory structure of a folder."
    )
    parser.add_argument("path", nargs="?", default=None,
                         help="Path to the folder you want to visualize")
    parser.add_argument(
        "--ignore", nargs="*", default=None,
        help="Additional folder/file names to ignore (space separated)"
    )
    parser.add_argument(
        "--no-default-ignore", action="store_true",
        help="Do not use the built-in default ignore list"
    )
    parser.add_argument(
        "--dirs-only", action="store_true",
        help="Show only directories, no files"
    )
    parser.add_argument(
        "--ext", nargs="*", default=None,
        help="Only include files with these extensions (e.g. --ext .dart .yaml)"
    )
    parser.add_argument(
        "--max-depth", type=int, default=None,
        help="Maximum depth to traverse (default: unlimited)"
    )
    parser.add_argument(
        "-o", "--output", default=None,
        help="File path to save/update the tree output as text"
    )
    parser.add_argument(
        "-y", "--yes", action="store_true",
        help="Skip all interactive prompts and use defaults for anything not passed as a flag"
    )
    parser.add_argument(
        "--zip", action="store_true",
        help="Create a zip archive of the folder (whole folder, or use --zip-folders)"
    )
    parser.add_argument(
        "--zip-folders", default=None,
        help="Comma separated sub-folder names (relative to path) to zip, e.g. reader,settings"
    )
    parser.add_argument(
        "--zip-output", default=None,
        help="Filename for the zip archive (default: <folder_name>.zip)"
    )

    args = parser.parse_args()

    # Track which options were explicitly given so we don't re-prompt for them
    args.ignore_asked = args.ignore is not None
    args.dirs_only_asked = args.dirs_only  # store_true flag: True only if passed
    args.ext_asked = args.ext is not None
    args.output_asked = args.output is not None
    args.zip_asked = args.zip  # store_true flag: True only if --zip was passed

    args.ignore = args.ignore or []

    if not args.yes:
        args = prompt_for_missing_args(args)
    elif not args.path:
        args.path = input("Enter the folder path: ").strip().strip('"').strip("'")

    if not os.path.isdir(args.path):
        print(f"Error: '{args.path}' is not a valid directory.", file=sys.stderr)
        sys.exit(1)

    ignore_set = set(args.ignore)
    if not args.no_default_ignore:
        ignore_set |= DEFAULT_IGNORE

    extensions = None
    if args.ext:
        extensions = {e if e.startswith(".") else f".{e}" for e in (x.lower() for x in args.ext)}

    lines, folder_count, file_count = build_tree(
        args.path,
        ignore_set,
        show_files=not args.dirs_only,
        max_depth=args.max_depth,
        extensions=extensions,
    )

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    header = f"Project structure for: {os.path.abspath(args.path)}\nGenerated: {timestamp}\n"
    body = "\n".join(lines)
    summary = f"\n\n{folder_count} directories, {file_count} files"
    output_text = header + "\n" + body + summary

    print(output_text)

    if args.output:
        # Always overwrite with the latest structure + fresh timestamp,
        # so re-running the script "updates" the file.
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output_text + "\n")
        print(f"\nStructure saved/updated: {args.output}")

    if args.zip:
        subfolders = None
        if args.zip_folders:
            subfolders = [s.strip() for s in args.zip_folders.split(",") if s.strip()]

        zip_path = create_zip(args.path, subfolders, args.zip_output, ignore_set)
        if zip_path:
            what = ", ".join(subfolders) if subfolders else os.path.basename(args.path.rstrip(os.sep))
            print(f"\nZip created for [{what}]: {zip_path}")


if __name__ == "__main__":
    main()