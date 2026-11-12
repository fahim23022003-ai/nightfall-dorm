"""Original Phase5D2 replay/cosmetic art; authored SVG, no external imagery."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
ART={
'endless':'<path d="M31 69q-20-43 33-52 53 9 33 52L83 81v23H45V81Z" fill="url(#metal)"/><path d="m25 15 12 17m66-17L91 32M29 112q-35-47 0-68m70 68q35-47 0-68"/><path d="m42 51 15 7-9 15-12-9m50-13-15 7 9 15 12-9" fill="#251922"/><path d="m63 66-7 15h16Zm-9 22v15m11-15v15m11-15v15" stroke="#2d1d2b"/>',
'challenge':'<path d="M27 14h73v98H27Z" fill="url(#metal)"/><path d="m50 42-15 17 15 17m28-34 15 17-15 17M69 35 57 83" stroke="#b4d3c8" stroke-width="6"/><path d="M43 96h38"/>',
'practice':'<circle cx="64" cy="65" r="45" fill="#1b2831"/><circle cx="64" cy="65" r="32"/><circle cx="64" cy="65" r="16"/><path d="M64 9v25m0 62v25M9 65h25m62 0h25" stroke-width="6"/><path d="m78 53 33-32-2 16-18 8Z" fill="url(#metal)"/>',
'cosmetic':'<path d="m24 26 40-13 40 13-7 61-33 28-33-28Z" fill="url(#metal)"/><path d="m37 52 19 8m35-8-19 8M43 84q21-15 42 0" stroke="#3a3449"/><path d="M47 31v10m17-15v13m17-8v10" stroke="#d7bd87"/>',
'analysis':'<path d="M25 20h77v94H25Z" fill="url(#metal)"/><path d="M39 37h50M39 52h29M39 70h13m-13 18h27"/><circle cx="84" cy="80" r="20" fill="#1e2930"/><path d="m99 96 14 17M84 68v16m0 8v1" stroke="#d4b687" stroke-width="6"/>',
'iron_gate':'<path d="M20 111V39q44-51 88 0v72Z" fill="#26343d"/><path d="M29 108V41q35-39 70 0v67Z" fill="url(#metal)"/><path d="M39 33v76m25-91v91m25-76v76M28 56h72M28 88h72" stroke="#283138" stroke-width="7"/><path d="M54 62h20v18H54Z" fill="#c0a56e"/>',
'coil_crown':'<ellipse cx="64" cy="105" rx="43" ry="9" fill="#0c121c"/><path d="M31 94V52l12-25 14 25v42m14 0V52l14-25 12 25v42" fill="url(#metal)"/><path d="M36 91h56M42 51h44"/><ellipse cx="64" cy="39" rx="43" ry="16" stroke="#bf9bcd" stroke-width="7"/><path d="M53 77V60h22v17Z" fill="#9ccfc2"/>',
'canopy':'<path d="M23 30q41-27 82 0l-8 24q-32-21-66 0Z" fill="#65506d"/><path d="M24 30v84m80-84v84M38 70v39m52-39v39" stroke="url(#metal)" stroke-width="7"/><path d="M29 80h69v25H29Z" fill="#8e839e"/><path d="M35 74h21v15H35Z" fill="#c6c6b7"/><path d="M65 83h28v18H65Z" fill="#615572"/>',
'reaper_crest':'<path d="m64 13 42 23-8 45-34 34-34-34-8-45Z" fill="url(#metal)"/><path d="m40 91 43-58m-8-10q29 2 31 29-20-15-43-5" stroke="#d5b77c" stroke-width="7"/><path d="M41 32q-26 21-12 42m58 14 15-19"/>'}
for name,body in ART.items():
 path=ROOT/'assets/premium_ui'/(name+'.svg')
 defs='<defs><linearGradient id="metal" x2=".3" y2="1"><stop stop-color="#d0cbb4"/><stop offset=".42" stop-color="#9a9e99"/><stop offset=".5" stop-color="#555766"/><stop offset="1" stop-color="#343342"/></linearGradient></defs>'
 path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128">{defs}<g fill="none" stroke="#12131e" stroke-width="8" stroke-linejoin="round" transform="translate(0 3)">{body}</g><g fill="none" stroke="#c5b493" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>')
