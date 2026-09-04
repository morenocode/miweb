from pathlib import Path
import re
import sys
import urllib.request

# Run the already validated v3.2 patch logic from the immutable commit that
# introduced it, then remove the two v3.1 declarations superseded by v3.2.
target = sys.argv[1]
core_url = (
    'https://raw.githubusercontent.com/morenocode/miweb/'
    '53073d908e3aa17f8dff9081efe8e18a8ec454b0/tools/patch_v32.py'
)
with urllib.request.urlopen(core_url, timeout=30) as response:
    core = response.read().decode('utf-8')

old_argv = sys.argv[:]
try:
    sys.argv = ['patch_v32_core.py', target]
    namespace = {'__name__': '__main__', '__file__': 'patch_v32_core.py'}
    exec(compile(core, 'patch_v32_core.py', 'exec'), namespace)
finally:
    sys.argv = old_argv

p = Path(target)
s = p.read_text(encoding='utf-8')

# v3.2 uses MissionHubCard instead of the old deterministic mission getter/card.
s, getter_count = re.subn(
    r"\n  String get _todayMission \{.*?\n  \}\n",
    "\n",
    s,
    count=1,
    flags=re.S,
)
s, card_count = re.subn(
    r"\nclass _MissionCard extends StatelessWidget \{.*?\n\}\n\nclass _MoodButton",
    "\nclass _MoodButton",
    s,
    count=1,
    flags=re.S,
)

if getter_count != 1:
    raise SystemExit('obsolete _todayMission getter not found')
if card_count != 1:
    raise SystemExit('obsolete _MissionCard class not found')

p.write_text(s, encoding='utf-8')
print(f'Clean v3.2 patch applied to {p}')
