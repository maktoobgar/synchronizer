import os

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

content = """# Changelog

## [Unreleased]

<!-- ## [0.0.2] - 2022-12-07

### Added

- /

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.0.1] - 2022-12-07

- initial release -->

<!-- Links -->
<!-- [keep a changelog]: https://keepachangelog.com/en/1.0.0/
[semantic versioning]: https://semver.org/spec/v2.0.0.html -->

<!-- Versions -->
<!-- [unreleased]: https://github.com/Author/Repository/compare/v0.0.2...HEAD
[0.0.2]: https://github.com/Author/Repository/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/Author/Repository/releases/tag/v0.0.1 -->
"""


def main():
    file = open(f"{CURRENT_DIR}/../CHANGELOG.md", "w")
    file.write(content)

    file.close()


if __name__ == "__main__":
    main()
