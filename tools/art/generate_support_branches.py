"""Original engraved upgrade emblems; no external imagery."""
from pathlib import Path
OUT=Path(__file__).resolve().parents[2]/'assets/premium_ui'
shapes={
'lucid':'<circle cx="32" cy="31" r="17"/><path d="M20 32h24M32 19v25"/>',
'conductor':'<path d="M38 12A22 22 0 1 0 49 46 19 19 0 0 1 38 12Z"/><path d="m32 25-8 12h9l-3 13 14-19h-11l5-6"/>',
'bulwark':'<path d="m15 17 17-6 17 6v20L32 53 15 37Z"/><path d="M23 19v21M41 19v21M17 30h30"/>',
'renewal':'<path d="m15 17 17-6 17 6v20L32 53 15 37Z"/><path d="M22 31h20M32 21v20"/>',
'regulated':'<rect x="15" y="19" width="34" height="29" rx="5"/><path d="M25 12h14M22 29h20M22 38h20"/>',
'overcharge':'<path d="m35 9-20 27h17l-4 20 22-30H34Z"/>',
'sustain':'<path d="M12 32h40M32 12v40"/><path d="m45 13-6 12h8l-5 12 14-19h-10l4-5"/>',
'conservation':'<path d="M12 23h25M24 11v26"/><circle cx="40" cy="43" r="14"/><path d="M40 33v20M34 39h12"/>',
'dividend':'<ellipse cx="30" cy="22" rx="17" ry="8"/><path d="M13 22v22c0 10 34 10 34 0V22M13 34c0 10 34 10 34 0"/>',
'capacitive':'<circle cx="28" cy="30" r="18"/><path d="M16 31h23M27 17v27m17-20-9 16h10l-5 15 16-23H45l5-8"/>',
'ballistic':'<circle cx="31" cy="33" r="19"/><circle cx="31" cy="33" r="10"/><path d="m31 33 22-23M44 11h9v9"/>',
'coolant':'<path d="M32 9v46M12 20l40 24M12 44l40-24M25 15l7 7 7-7M25 49l7-7 7 7M15 28l7-2-2-8M44 48l-2-10 9-1"/>'}
for i,(name,body) in enumerate(shapes.items()):
 color=['#DCC38A','#9FD9D6','#ACBBDD','#B7D3B6'][i%4]
 svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><rect x="2" y="2" width="60" height="60" rx="10" fill="#1B2028" stroke="{color}" stroke-width="2"/><g fill="#2D3944" stroke="{color}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">{body}</g></svg>'
 (OUT/(name+'.svg')).write_text(svg)
print('ORIGINAL_BRANCH_EMBLEMS',len(shapes))
