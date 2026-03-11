#!/usr/bin/env python3
"""
Generate / update a notebook index in README.md.

Walks the repository root directory, finds all first-level directories
(sorted alphabetically), and for each of them looks for `.ipynb`
files (non-hidden, sorted).  For every notebook it checks whether a
same-name `.html` exists; if not it looks for a `.pdf` version.

Builds a markdown nested list like:

- 01_Netflix_EDA
  - netflix_solution.ipynb - [ipynb](01_Netflix_EDA/netflix_solution.ipynb)
    | [html](01_Netflix_EDA/netflix_solution.html)
  - other.ipynb - [ipynb](path/to/other.ipynb)
    | [pdf](path/to/other.pdf)

and then ensures that the README contains that block between the
markers `<!-- NOTEBOOK INDEX START -->` and
`<!-- NOTEBOOK INDEX END -->`.  If the markers are missing it appends a
new section titled `## Index of Notebooks` with the markers and the
content.  The script is idempotent: running it repeatedly produces the
same README if nothing has changed.

At the end the generated markdown (bullet list) is printed to stdout.
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Optional

# repository root is the parent of this script's directory
ROOT = Path(__file__).resolve().parent.parent
README = ROOT / "README.md"
START_MARKER = "<!-- NOTEBOOK INDEX START -->"
END_MARKER = "<!-- NOTEBOOK INDEX END -->"


def find_top_level_dirs(root: Path) -> List[Path]:
    return sorted([p for p in root.iterdir() if p.is_dir()], key=lambda p: p.name.lower())


def list_notebooks(folder: Path) -> List[Path]:
    return sorted(
        [p for p in folder.iterdir() if p.is_file()
         and p.suffix == ".ipynb"
         and not p.name.startswith(".")],
        key=lambda p: p.name.lower(),
    )


def find_output_file(nb: Path) -> Optional[Path]:
    for ext in (".html", ".pdf"):
        candidate = nb.with_suffix(ext)
        if candidate.exists():
            return candidate
    return None


def build_index_md(root: Path) -> str:
    lines: List[str] = []
    for folder in find_top_level_dirs(root):
        notebooks = list_notebooks(folder)
        if not notebooks:
            continue
        lines.append(f"- {folder.name}")
        for nb in notebooks:
            rel_nb = nb.relative_to(root).as_posix()
            output = find_output_file(nb)
            output_link = ""
            if output:
                rel_out = output.relative_to(root).as_posix()
                output_link = f" | [{output.suffix.lstrip('.')}](" \
                              f"{rel_out})"
            lines.append(
                f"  - {nb.name} - [ipynb]({rel_nb}){output_link}"
            )
    return "\n".join(lines)


def replace_section(original: str, new_content: str) -> str:
    """Replace text between START_MARKER and END_MARKER (inclusive of markers)."""
    pattern = re.compile(
        re.escape(START_MARKER) + r".*?" + re.escape(END_MARKER),
        flags=re.DOTALL
    )
    replacement = f"{START_MARKER}\n{new_content}\n{END_MARKER}"
    return pattern.sub(replacement, original)


def main():
    index_md = build_index_md(ROOT)

    # read README
    if README.exists():
        text = README.read_text(encoding="utf-8")
    else:
        text = ""

    if START_MARKER in text and END_MARKER in text:
        # replace between markers
        new_text = replace_section(text, index_md)
    else:
        # append a new section
        sep = "\n" if text and not text.endswith("\n") else ""
        new_text = (
            text
            + sep
            + "\n## Index of Notebooks\n\n"
            + f"{START_MARKER}\n{index_md}\n{END_MARKER}\n"
        )

    # write back only if changed
    if new_text != text:
        README.write_text(new_text, encoding="utf-8")
    # print generated markdown (without markers)
    print(index_md)


if __name__ == "__main__":
    main()
