#!/bin/bash
# Claude Code StatusLine Script
# Display: directory | model | context usage progress bar
python -c "
import sys, json, os
sys.stdout.reconfigure(encoding='utf-8')
try:
    data = json.load(sys.stdin)
except:
    print('statusline error')
    sys.exit(0)

cwd = data.get('workspace',{}).get('current_dir','') or os.getcwd()
dir_name = os.path.basename(cwd.replace(chr(92)*2,'/'))
model_id = data.get('model',{}).get('id','unknown')
short = model_id.replace('astron-code-latest','astron').replace('claude-opus-4-8','opus-4.8').replace('claude-sonnet-4-6','sonnet-4.6').replace('claude-haiku-4-5-20251001','haiku-4.5')
ctx_rem = int(data.get('context_window',{}).get('remaining_percentage',100))
ctx_used = 100 - ctx_rem

# Progress bar: 10 blocks
total = 10
filled = round(ctx_used * total / 100)
empty = total - filled
bar = chr(9608) * filled + chr(9617) * empty

# Color indicator
if ctx_rem >= 50: tag = 'OK'
elif ctx_rem >= 20: tag = 'LOW'
else: tag = 'CRIT'

print(f'{dir_name} | {short} | {bar} {ctx_used}% {tag}')
"
