"""Shared escaping between import_from_a_txt.py (writer) and driver.py (reader)
so a command's real newlines/tabs/backslashes survive a round trip through a
single-line TSV field.
"""


def encode_cell(raw: str) -> str:
    return raw.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")


def decode_cell(s: str) -> str:
    out = []
    i = 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            nc = s[i + 1]
            if nc == "n":
                out.append("\n")
                i += 2
                continue
            if nc == "t":
                out.append("\t")
                i += 2
                continue
            if nc == "\\":
                out.append("\\")
                i += 2
                continue
        out.append(c)
        i += 1
    return "".join(out)
