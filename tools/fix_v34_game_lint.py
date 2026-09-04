from pathlib import Path
import sys

p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
old="Expanded(child: _Pill(icon: '✅', text: '$_correct'))"
new="Expanded(child: _Pill(icon: '✅', text: '$_correct · ❌ $_wrong'))"
if old not in s:
    raise SystemExit('score pill marker not found')
p.write_text(s.replace(old,new,1),encoding='utf-8')
print('Displayed correct and wrong counters')
