#!env/bin/python
# Install hooks

import os
import generate_changelog

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

def generate_changelog_template():
    if not os.path.isfile(f"{CURRENT_DIR}/../CHANGELOG.md"):
        generate_changelog.main()
        print("CHANGELOG.md template added")

def configure_git_config():
    text = "\thooksPath = .githooks"

    if not os.path.exists(f"{CURRENT_DIR}/../.git"):
        print("no .git folder found")
        return

    f = open(f"{CURRENT_DIR}/../.git/config", "r")
    lines = f.readlines()
    lines_string = ""
    for line in lines:
        # adding config in core
        if line.strip() == "[core]":
            lines_string = line + text + "\n"
            continue
        # if configuration happened before, quit
        if line.strip().find(text.strip()) != -1:
            return
        lines_string += line
    f.close()

    f = open(f"{CURRENT_DIR}/../.git/config", "w")
    f.write(lines_string)
    f.close()

    print("git hooks activated")

def setup_virtual_env():
    # env folder creation
    if not os.path.isdir(f"{CURRENT_DIR}/../env"):
        print("setting up virtual env")
        os.system(f"python3 -m venv {CURRENT_DIR}/../env")

def generate_setup_file_template():
    if not os.path.isfile(f"{CURRENT_DIR}/../setup.py"):
        print("setting up setup file")
        os.system(f"cp {CURRENT_DIR}/setup_file {CURRENT_DIR}/../setup.py")

def main():
    setup_virtual_env()
    configure_git_config()
    generate_changelog_template()
    generate_setup_file_template()

if __name__ == "__main__":
    main()
