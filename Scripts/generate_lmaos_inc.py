from enum import Enum
import operator
import re
import sys


class ExportedSymbol:
    def __init__(self, name, address, type) -> None:
        self.name = name
        self.address = int(address, base=16)
        self.is_zeropage = (type == "LZ")

    @classmethod
    def create_valid_export(klass, name, address, type):
        if re.match("^__\w+__$", name):
            return None
        else:
            return klass(name, address, type)


class ReadState(Enum):
    LOOKING_FOR_EXPORTS = 1
    LOOKING_FOR_DIVIDER = 2
    PARSING_EXPORTS = 3


def is_divider(string):
    return re.match("-+", string)


def is_export_by_value(string):
    return re.match("Exports list by value:", string)


def tokenize_export_list(string):
    tokens = string.split()

    num_tokens = len(tokens)
    if num_tokens != 3 and num_tokens != 6:
        return None

    exports = []

    # 2 sets of 3 args here: name, address, and a 2 letter type
    first = ExportedSymbol.create_valid_export(tokens[0], tokens[1], tokens[2])

    second = None
    if num_tokens == 6:
        second = ExportedSymbol.create_valid_export(tokens[3], tokens[4], tokens[5])

    return filter(None, [first, second])


try:
    map_file = sys.argv[1]
    dest_file = sys.argv[2]
except IndexError:
    raise SystemExit(f"Usage: {sys.argv[0]} <rom_map_file> <include_destination_file")

read_state = ReadState.LOOKING_FOR_EXPORTS
exports = []

with open(map_file, "r") as file:
    for line in file:
        if read_state == ReadState.LOOKING_FOR_EXPORTS:
            if is_export_by_value(line):
                read_state = ReadState.LOOKING_FOR_DIVIDER
        elif read_state == ReadState.LOOKING_FOR_DIVIDER:
            if is_divider(line):
                read_state = ReadState.PARSING_EXPORTS
        elif read_state == ReadState.PARSING_EXPORTS:
            newExports = tokenize_export_list(line)
            if newExports is None:
                break
            else:
                exports.extend(newExports)

zeropage = [x for x in exports if x.is_zeropage]
rest = sorted([x for x in exports if not x.is_zeropage], key=operator.attrgetter('address'))

with open(dest_file, "w") as generated:
    generated.write("""; LmaOS
;
; Copyright Nate Rivard 2021
;
; A full listing of system provided storage and subroutines.
;
; THIS FILE IS GENERATED
;
; NOTE: This is not imported in LmaOS itself, it is for your external program use _only_!
; You should copy and paste this file into your program's project to expose system utility subroutines
; and any allocated system storage you should avoid using.

.ifndef LMAOS_INC
LMAOS_INC = 1

; Zero-page reserved
""")

    for zp in zeropage:
        generated.write(f"{zp.name:<30}:= ${zp.address:02X}\n")

    generated.write("""
; RAM reserved
; TODO: Open a MR if you have figured this out :)

; Read-only
""")

    for ram in rest:
        generated.write(f"{ram.name:<30}:= ${ram.address:04X}\n")

    generated.write("""
.endif
""")

    generated.close()
