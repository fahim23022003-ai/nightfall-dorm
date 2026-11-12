#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'assets'/'items';root.mkdir(exist_ok=True)
paths={
'repair':('<path d="M18 28h60v46H18z" fill="#52776c"/><path d="M35 28v-8h26v8" fill="none" stroke="#a9d3c7" stroke-width="5"/><path d="M43 37h10v12h12v10H53v12H43V59H31V49h12z" fill="#b3ffce"/>','#74e5a3'),
'gold':('<path d="M18 35l30-15 30 15v39H18z" fill="#9a6b38"/><path d="M18 35h60M48 35v39M18 74l30-15 30 15" stroke="#eec674" fill="none" stroke-width="4"/><circle cx="48" cy="43" r="15" fill="#ffd66c" stroke="#9c7229" stroke-width="3"/><path d="M48 33v20m-5-17h10m-10 14h10" stroke="#a47b2f" stroke-width="3"/>','#ffd368'),
'battery':('<rect x="26" y="23" width="44" height="57" rx="9" fill="#255c7c" stroke="#a1deef" stroke-width="3"/><path d="M38 23v-8h20v8" fill="#b3dde8"/><path d="M51 31L35 54h12l-3 18 18-26H50z" fill="#8aebff"/>','#64dffd'),
'radar':('<circle cx="48" cy="49" r="29" fill="#194b50" stroke="#a5f7d8" stroke-width="3"/><circle cx="48" cy="49" r="18" fill="none" stroke="#528b83"/><path d="M18 49h60M48 19v60M48 49l20-20" stroke="#90efd0" stroke-width="2"/><circle cx="61" cy="36" r="5" fill="#e6ffe1"/>','#86e0ce'),
'shield':('<path d="M48 15l29 12v25q-3 20-29 31Q22 72 19 52V27z" fill="#285e91" stroke="#a4dcff" stroke-width="4"/><path d="M48 25v45M30 45h36" stroke="#64b5ff" stroke-width="5"/><path d="M48 28l13 22-13 21-13-21z" fill="#c0edff"/>','#65b5ff'),
'overdrive':('<path d="M26 52l22-35 23 35-12 25H36z" fill="#854936" stroke="#ffd092" stroke-width="3"/><path d="M46 30L32 55h14l-4 17 24-31H51l5-14" fill="#ffe09d"/><path d="M18 39l-8 14m68-14 8 14" stroke="#f5a85e" stroke-width="4"/>','#f5a85e'),
'frost':('<path d="M48 15v67M19 32l58 34M19 66l58-34" stroke="#d9f6ff" stroke-width="5"/><path d="M37 24l11 11 11-11M37 73l11-11 11 11M20 45l14-3-2-14M65 70l-2-14 14-3M20 53l14 3-2 14M65 28l-2 14 14 3" fill="none" stroke="#8cc9ed" stroke-width="4"/>','#a6dbff'),
'trap':('<path d="M20 62l13-28h30l13 28-14 17H34z" fill="#673c44" stroke="#e8afb1" stroke-width="3"/><path d="M36 35l-9-12m34 12 9-12M20 62h56" stroke="#d99090" stroke-width="4"/><circle cx="48" cy="54" r="12" fill="#ffac71"/><path d="M48 44v13m0 5v3" stroke="#6e343e" stroke-width="4"/>','#f78e88')}
for name,(body,color) in paths.items():
 (root/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96"><rect x="3" y="3" width="90" height="90" rx="21" fill="#162939" stroke="{color}" stroke-width="3"/>{body}</svg>')
