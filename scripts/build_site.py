#!/usr/bin/env python3
"""Prepare Lean parameters and check the generated MDX site.

The default command delegates compilation to the website Node.js build.
Parameter and link checks do not check Lean proofs.
"""

from fractions import Fraction
from html.parser import HTMLParser
from pathlib import Path
import argparse
import json
import re
import shutil
import struct
import subprocess
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "website"
OUT = ROOT / "artifacts/site"


class Links(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links = []
        self.ids = set()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            if attrs["id"] in self.ids:
                raise ValueError(f"Duplicate HTML id: {attrs['id']}")
            self.ids.add(attrs["id"])
        for attr in ("href", "src"):
            if attrs.get(attr):
                self.links.append(attrs[attr])


def check_links():
    documents = {}
    count = 0
    for path in OUT.rglob("*.html"):
        parser = Links()
        parser.feed(path.read_text())
        documents[path.resolve()] = parser
    for page, parser in documents.items():
        for link in parser.links:
            url = urlsplit(link)
            if url.scheme or url.netloc:
                continue
            target = (page.parent / unquote(url.path)).resolve() if url.path else page
            if target.is_dir():
                target /= "index.html"
            if not target.is_relative_to(OUT.resolve()) or not target.is_file():
                raise ValueError(f"Broken local link in {page.relative_to(OUT)}: {link}")
            if url.fragment and (target not in documents or unquote(url.fragment) not in documents[target].ids):
                raise ValueError(f"Missing anchor in {page.relative_to(OUT)}: {link}")
            count += 1
    return count


def prepare():
    # Only generated public files go into this disposable output directory.
    if OUT.exists():
        shutil.rmtree(OUT)
    (OUT / "assets").mkdir(parents=True)
    shutil.copyfile(SITE / "assets/style.css", OUT / "assets/style.css")

    parameter_source = (ROOT / "NeuralSpec/Network/Xor/Parameters.lean").read_text()
    definitions = dict(re.findall(r"^def (\w+) : ℚ := (-?\d+ / \d+)$", parameter_source, re.M))
    order = re.search(r"def parameters : List ℚ :=\s*\[([^]]+)\]", parameter_source)[1].replace(" ", "").split(",")
    if len(order) != 22 or set(order) != set(definitions):
        raise ValueError("The XOR explorer expects the 22 frozen row-major parameters")
    rationals = [Fraction(definitions[name].replace(" ", "")) for name in order]
    bits = re.search(r"def sourceBits32 : List UInt32 :=\s*\[([^]]+)\]", parameter_source)[1]
    words = [int(word.strip()) for word in bits.split(",")]
    if len(words) != len(rationals):
        raise ValueError("Parameter word count differs from rational count")
    for rational, word in zip(rationals, words):
        decoded = struct.unpack("!f", struct.pack("!I", word))[0]
        if Fraction.from_float(decoded) != rational:
            raise ValueError("Rational parameter differs from its binary32 word")
    (OUT / "assets/parameters.mjs").write_text(
        "// Generated from NeuralSpec/Network/Xor/Parameters.lean.\n"
        + "export const parameters = " + json.dumps([float(x) for x in rationals]) + ";\n")
    (OUT / ".nojekyll").touch()
    print("Checked all 22 frozen parameter encodings")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--prepare", action="store_true")
    modes.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.prepare:
        prepare()
    elif args.check:
        if re.search(r"{{[^{}]+}}", (OUT / "index.html").read_text()):
            raise ValueError("Unexpanded placeholder in index.html")
        count = check_links()
        print(f"Built one page in {OUT.relative_to(ROOT)}; checked {count} local links")
    else:
        subprocess.run(["npm", "--prefix", str(SITE), "run", "build"], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
