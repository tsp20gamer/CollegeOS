import re
from pathlib import Path

# TimetableEntry/NewTimetableEntry records gained a reminder field; every
# literal in these tests ends with its `note:` field, so insert the new field
# right after it with matching indentation.
FILES = [
    'test/features/home_widget/domain/home_widget_projection_test.dart',
    'test/features/timetable/timetable_services_test.dart',
    'test/features/timetable/timetable_import_test.dart',
    'test/features/timetable/timetable_persistence_test.dart',
]
pattern = re.compile(r'^([ \t]*)(note: [^\n]*,\n)([ \t]*\)[\),;]?\n)', re.M)


def patch(match: re.Match) -> str:
    indent, note_line, close = match.groups()
    return f'{indent}{note_line}{indent}reminderMinutesBefore: null,\n{close}'


for name in FILES:
    path = Path(name)
    source = path.read_text(encoding='utf-8')
    patched, count = pattern.subn(patch, source)
    assert count > 0, f'no record literal found in {name}'
    assert 'reminderMinutesBefore' not in source, f'{name} already patched'
    path.write_text(patched, encoding='utf-8')
    print(f'{name}: {count} literals')
