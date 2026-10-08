import re
from pathlib import Path

# Every record literal in this file is a TimetableEntry/NewTimetableEntry, and
# each one ends with its `note:` field.
name = 'test/features/timetable/timetable_persistence_test.dart'
path = Path(name)
source = path.read_text(encoding='utf-8')
pattern = re.compile(r'^([ \t]*)(note: [^\n]*,\n)([ \t]*\)[^\n]*\n)', re.M)


def patch(match: re.Match) -> str:
    indent, note_line, close = match.groups()
    return f'{indent}{note_line}{indent}reminderMinutesBefore: null,\n{close}'


assert 'reminderMinutesBefore' not in source
patched, count = pattern.subn(patch, source)
assert count == 8, count
path.write_text(patched, encoding='utf-8')
print(f'{name}: {count} literals')
