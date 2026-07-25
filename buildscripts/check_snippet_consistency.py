#!/usr/bin/env python3
"""Assert a definition renders the same as a snippet and on its generated page.

A test that ships `markdown/` is rendered twice from one registry: `generate`
writes `expected/<namespace>/<signal>.md`, `update-markdown` fills the markers in
`expected-markdown/`. Both go through the same macros, so the body of a
definition must come out byte for byte identical - `snippet.md.j2` and the
`*_namespace.md.j2` pages differing in, say, a blank line is a bug that two
independent expected trees cannot catch on their own.

Usage: check_snippet_consistency.py <expected-markdown-dir> <expected-dir>
"""

import pathlib
import re
import sys

# `.registry.<collection>` -> the page `generate` writes it to. Attribute groups
# are snippet-only by design, so there is nothing to compare them against.
PAGES = {
    "spans": "spans.md",
    "metrics": "metrics.md",
    "events": "events.md",
    "entities": "entities.md",
}
SNIPPET_ONLY = {"attribute_groups"}

BLOCK = re.compile(
    r"<!-- weaver (?P<filter>.*?) -->\n"
    r"(?P<rendered>.*?)"
    r"<!-- endweaver -->",
    re.DOTALL,
)
BODY = re.compile(
    r"<!-- prettier-ignore-start -->\n(?P<body>.*?)<!-- prettier-ignore-end -->",
    re.DOTALL,
)
# Only the `select(.<field> == "<id>")` shape can be traced back to a page.
FILTER = re.compile(
    r'\.registry\.(?P<collection>\w+)\[\]\s*\|\s*select\(\.\w+\s*==\s*"(?P<id>[^"]+)"\)'
)


def generated_section(pages_dir, collection, definition_id):
    """The body of `## `<definition_id>`` on the page `generate` wrote it to."""
    namespace = definition_id.split(".")[0]
    page = pages_dir / namespace / PAGES[collection]
    if not page.is_file():
        return None, f"no generated page {page}"
    heading = f"## `{definition_id}`"
    lines = page.read_text().splitlines()
    if heading not in lines:
        return None, f"no section {heading} in {page}"
    start = lines.index(heading) + 1
    end = next(
        (i for i in range(start, len(lines)) if lines[i].startswith("## ")),
        len(lines),
    )
    return "\n".join(lines[start:end]), None


def main(snippets_dir, pages_dir):
    snippets_dir, pages_dir = pathlib.Path(snippets_dir), pathlib.Path(pages_dir)
    compared = skipped = 0
    failures = []

    for doc in sorted(snippets_dir.rglob("*.md")):
        for block in BLOCK.finditer(doc.read_text()):
            jq = block.group("filter").strip()
            match = FILTER.search(jq)
            if not match:
                failures.append(f"{doc}: cannot map filter to a page: {jq}")
                continue
            collection, definition_id = match.group("collection"), match.group("id")
            if collection in SNIPPET_ONLY:
                skipped += 1
                continue
            if collection not in PAGES:
                failures.append(f"{doc}: unknown collection `{collection}` in: {jq}")
                continue

            body = BODY.search(block.group("rendered"))
            if not body:
                failures.append(f"{doc}: {definition_id} rendered no snippet body")
                continue

            section, err = generated_section(pages_dir, collection, definition_id)
            if err:
                failures.append(f"{doc}: {definition_id}: {err}")
                continue

            compared += 1
            if body.group("body").strip() != section.strip():
                failures.append(
                    f"{definition_id}: snippet and generated page disagree\n"
                    + "".join(
                        f"    {line}\n"
                        for line in _diff(section.strip(), body.group("body").strip())
                    ).rstrip()
                )

    for failure in failures:
        print(f"  ❌ FAIL: {failure}")
    if failures:
        return 1
    print(
        f"  ✅ PASS: {compared} definition(s) render identically both ways"
        + (f", {skipped} snippet-only skipped." if skipped else ".")
    )
    return 0


def _diff(page, snippet):
    import difflib

    return difflib.unified_diff(
        page.splitlines(),
        snippet.splitlines(),
        fromfile="generated page",
        tofile="snippet",
        lineterm="",
    )


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    sys.exit(main(sys.argv[1], sys.argv[2]))
