"""Original engraved action emblems and illustrated supplies, Phase5D-1.
No stock artwork or runtime network dependency. Deterministic SVG source.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/premium_ui';OUT.mkdir(exist_ok=True)
ART={
'play':'<path d="M38 105V38Q64 0 90 38v67Z" fill="url(#steel)"/><path d="M47 99V40q17-27 34 0v59Z" fill="#10171a"/><path d="m58 49 22 17-22 17Z" fill="url(#gold)"/><path d="M28 107h72M64 18v15"/>',
'shop':'<path d="m30 44 13-23h42l13 23-7 60H37Z" fill="url(#steel)"/><path d="M43 27q21 27 42 0M30 47q34 19 68 0"/><circle cx="64" cy="75" r="17" fill="url(#gold)"/><path d="M64 63v24m-7-20h10m-10 16h10" stroke="#453c23"/>',
'inventory':'<path d="M28 46q36-30 72 0v55H28Z" fill="url(#steel)"/><path d="M44 34V22h40v12M28 60h72M41 60v41m46-41v41"/><path d="M57 51h14v22H57Z" fill="url(#gold)"/>',
'loadout':'<path d="m29 27 72 74m-1-74-71 74" stroke="#101719" stroke-width="15"/><path d="m29 27 72 74m-1-74-71 74" stroke="url(#steel)" stroke-width="9"/><path d="m24 85 18 18m44-79 18 18" stroke="url(#gold)" stroke-width="9"/><path d="m20 22 14 2-10 10Z" fill="url(#gold)"/>',
'rank':'<path d="m64 12 38 18-7 51-31 31-31-31-7-51Z" fill="url(#steel)"/><path d="m64 30 8 18 20 2-15 14 4 21-17-10-17 10 4-21-15-14 20-2Z" fill="url(#gold)"/>',
'achievement':'<path d="M43 23h42v35q-4 26-21 26T43 58Z" fill="url(#gold)"/><path d="M43 31H24v20q0 18 22 19m39-39h19v20q0 18-22 19M64 84v19m-22 6h44"/><path d="m59 37 12 12-12 12" stroke="#4c472e"/>',
'tutorial':'<path d="M64 35q-23-16-47-7v69q24-10 47 6 23-16 47-6V28q-24-9-47 7Z" fill="url(#steel)"/><path d="M64 36v67M27 43l25 5M27 58l25 5M27 73l25 5M76 46l23-4M76 62l23-4"/><path d="M84 81v-9q11-9 4-19 19 12 10 27Z" fill="url(#gold)"/>',
'settings':'<path d="m55 14 18 0 3 15 13 7 14-5 9 17-12 10v15l12 10-9 17-14-5-13 7-3 15H55l-3-15-13-7-14 5-9-17 12-10V58L16 48l9-17 14 5 13-7Z" fill="url(#steel)"/><circle cx="64" cy="65" r="20" fill="#141d21"/><circle cx="64" cy="65" r="9" fill="url(#gold)"/>',
'pause':'<path d="M34 24h20v80H34Zm40 0h20v80H74Z" fill="url(#steel)"/><path d="M37 27h13m27 0h13" stroke="url(#gold)"/>',
'next':'<path d="M26 102V32l24-15 24 15v20H55v50Z" fill="url(#steel)"/><path d="M50 73h47M80 50l24 23-24 23" stroke="url(#gold)" stroke-width="10"/>',
'retry':'<path d="M96 43a39 39 0 1 0 3 39" stroke="url(#steel)" stroke-width="13"/><path d="m78 16 26 4-2 29-26-5Z" fill="url(#gold)"/>',
'build':'<path d="m30 99 57-65 12 10-57 65Z" fill="url(#steel)"/><path d="m63 18 15-8 32 28-16 17Z" fill="url(#gold)"/><path d="M25 104h78M29 94l15 12"/>',
'repair':'<path d="m29 102 49-53q-6-19 6-30l4 22 16-1 7-22q15 21-7 39l-48 53Z" fill="url(#steel)"/><path d="M22 33h26v36H22Z" fill="url(#gold)"/><path d="M35 24v54M15 51h40" stroke="#d5d0ae"/>',
'upgrade':'<path d="M37 109V65H18l46-49 46 49H91v44Z" fill="url(#steel)"/><path d="m43 58 21-23 21 23M46 94h36" stroke="url(#gold)" stroke-width="7"/>',
'sell':'<circle cx="78" cy="44" r="27" fill="url(#gold)"/><path d="M78 27v34m-9-27h18m-18 20h18" stroke="#57482a"/><path d="M18 83h56m-39-18L16 83l19 19" stroke="url(#steel)" stroke-width="10"/><path d="M61 88q15 19 44-1"/>',
'gold':'<ellipse cx="64" cy="70" rx="41" ry="37" fill="#574326"/><ellipse cx="64" cy="61" rx="41" ry="37" fill="url(#gold)"/><ellipse cx="64" cy="61" rx="30" ry="27" stroke="#74613b"/><path d="m65 35-18 29h15l-5 23 25-32H67Z" fill="#7a6033"/>',
'power':'<path d="m69 12-40 57h29l-9 47 50-66H72l11-38Z" fill="url(#cyan)"/><path d="m34 21-13 8 7 18m71 36 12 11-12 13" stroke="#52959c"/>',
'cash':'<path d="M12 33h104v65H12Z" fill="url(#cash)"/><path d="M20 40h88v50H20Z" stroke="#ac9d63"/><ellipse cx="64" cy="65" rx="22" ry="20" fill="#293e32"/><path d="M53 76V54h10q16 0 7 12l11 10m-18-11h-9" stroke="url(#gold)"/><path d="M28 52v26m72-26v26"/>',
'standard':'<path d="m64 17 34 16-6 49-28 26-28-26-6-49Z" fill="url(#steel)"/><path d="m44 63 14 14 28-31" stroke="#b3c8aa" stroke-width="8"/>',
'hard':'<path d="M83 18q-48 4-48 47 0 44 49 47-68 16-73-43 1-52 72-51Z" fill="#aba2cc"/><path d="m90 43 5 13 15 1-12 10 4 14-12-8-12 8 4-14-12-10 15-1Z" fill="url(#gold)"/>',
'hell':'<path d="M42 97q-44-18-14-59l12 20q-6-32 29-47-4 24 18 44l12-18q36 56-15 73Z" fill="url(#fire)"/><path d="M47 92q-17-20 11-43-4 24 15 24l8-9q19 32-16 40Z" fill="#d4a15d"/><path d="m47 88 10-5m15 5 8-5" stroke="#32242a"/>',
'fortified':'<path d="m64 13 39 22-8 50-31 29-31-29-8-50Z" fill="url(#steel)"/><path d="M42 42h44v42H42Zm22 0v42M42 63h44" stroke="url(#gold)"/>',
'precision':'<circle cx="64" cy="64" r="38" stroke="url(#gold)"/><circle cx="64" cy="64" r="19"/><path d="M64 10v32m0 44v32M10 64h32m44 0h32"/><circle cx="64" cy="64" r="5" fill="#d9cda6"/>',
'suppression':'<path d="M22 96 55 34h18l33 62Z" fill="url(#steel)"/><path d="M44 61h40M37 76h54M52 31v-9m12 9V13m12 18v-9" stroke="url(#cyan)"/><path d="M25 108h78"/>',
'focus':'<path d="m64 14-26 49h20l-4 51 37-65H70l12-35Z" fill="url(#cyan)"/><circle cx="64" cy="64" r="41" stroke="#ac9bca"/>',
'storm':'<path d="M19 37h90M19 64h90M19 91h90" stroke="#746b99"/><path d="m34 24-15 32h19l-9 24m35-63L49 57h22L58 91m38-49L82 74h20l-9 32" stroke="url(#cyan)" stroke-width="6"/>',
'crusher':'<path d="M24 101V49l18-22h44l18 22v52Z" fill="url(#steel)"/><path d="M37 49h54v45H37Z" fill="#343238"/><path d="m42 59 14 4m30-4-14 4M45 85h38" stroke="url(#gold)"/><path d="m19 34-5-14m95 14 5-14" stroke-width="9"/>',
'stalker':'<path d="M20 107q-9-68 44-93 53 25 44 93L80 90H48Z" fill="url(#steel)"/><path d="M37 64q27-24 54 0-27 32-54 0Z" fill="#13171e"/><path d="m47 65 12 1m10 0 12-1" stroke="#b5a0d0" stroke-width="6"/>',
'ravager':'<path d="m28 104 5-65 31-26 31 26 5 65-36-19Z" fill="url(#steel)"/><path d="m38 52 19 10m33-10-19 10" stroke="#d38476" stroke-width="7"/><path d="m43 82 11-8 10 12 10-12 11 8M25 24 14 66m89-42 11 42"/>',
'contract':'<path d="M30 18h70v79l-17 13-15-7-16 7-22-13Z" fill="url(#steel)"/><path d="M44 38h43M44 53h43M44 68h24"/><circle cx="83" cy="86" r="15" fill="url(#gold)"/><path d="m76 86 5 5 10-12" stroke="#494530"/>'}
for name,body in ART.items():
 color={'hell':'#cc7465','hard':'#b3a3d0','power':'#90d2d7','cash':'#b6bf91'}.get(name,'#c2b99a')
 svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><defs><linearGradient id="steel" x2=".3" y2="1"><stop stop-color="#ccd0bd"/><stop offset=".42" stop-color="#768b83"/><stop offset=".5" stop-color="#495b58"/><stop offset="1" stop-color="#263438"/></linearGradient><linearGradient id="gold" x2=".3" y2="1"><stop stop-color="#f3e1a3"/><stop offset=".48" stop-color="#b79b57"/><stop offset="1" stop-color="#665332"/></linearGradient><linearGradient id="cyan" x2=".4" y2="1"><stop stop-color="#c5f3e5"/><stop offset="1" stop-color="#408d9e"/></linearGradient><linearGradient id="cash" x2=".2" y2="1"><stop stop-color="#78967a"/><stop offset="1" stop-color="#243e37"/></linearGradient><linearGradient id="fire" x2=".2" y2="1"><stop stop-color="#dc9563"/><stop offset="1" stop-color="#72333e"/></linearGradient></defs><g fill="none" stroke="#02080b" stroke-width="7" stroke-linejoin="round" stroke-linecap="round" transform="translate(0 3)">{body}</g><g fill="none" stroke="{color}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>'''
 (OUT/(name+'.svg')).write_text(svg)
# Common supply illustrations use the same local inventory identities, with
# distinct physical silhouettes, material highlights, shadows and engraved detail.
SUPPLIES={
'repair':'<path d="M19 64h91v43H19Z" fill="url(#steel)"/><path d="M33 64V49h63v15M19 78h91"/><path d="m28 30 51 57 12-10-51-57Z" fill="url(#gold)"/><path d="M70 23 84 12l22 20-14 15Z" fill="url(#steel)"/><path d="M45 92h39m-19-8v16" stroke="#bbc9ab"/>',
'gold':'<path d="M18 62q46-34 92 0v44H18Z" fill="#514535"/><path d="M18 60q46-45 92 0l-9 16H27Z" fill="url(#gold)"/><path d="M30 67v38m67-38v38M17 87h94"/><path d="M57 75h16v25H57Z" fill="url(#gold)"/><circle cx="45" cy="57" r="12" fill="url(#gold)"/><circle cx="67" cy="48" r="14" fill="url(#gold)"/><circle cx="89" cy="57" r="12" fill="url(#gold)"/><path d="m31 23 3 9m67-9-5 9M65 9v10" stroke="#d4c79b"/>',
'battery':'<path d="M46 15h37v13H46Z" fill="url(#gold)"/><path d="M32 28h64v80H32Z" fill="url(#steel)"/><path d="M39 37h50v62H39Z" fill="#182c33"/><path d="m68 38-21 35h18l-6 25 26-39H68Z" fill="url(#cyan)"/><path d="m18 45-7 14 10 14m87-39 10 14-8 17" stroke="#6dc7cb"/>',
'radar':'<path d="M30 29h71v76H30Z" fill="url(#steel)"/><path d="M41 29V12m46 17V18" stroke-width="6"/><circle cx="65" cy="63" r="28" fill="#11282b"/><circle cx="65" cy="63" r="20" stroke="#527b72"/><circle cx="65" cy="63" r="10" stroke="#527b72"/><path d="m65 63 18-19-6 23Z" fill="#94bd99"/><path d="M37 63h55M65 37v54" stroke="#587a71"/><circle cx="76" cy="52" r="4" fill="#e4c985"/><path d="M43 99h42" stroke="url(#gold)"/>'}
for name,body in SUPPLIES.items():
 base=(OUT/'shop.svg').read_text();defs=base[base.index('<defs>'):base.index('</defs>')+7]
 svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128">{defs}<ellipse cx="65" cy="113" rx="49" ry="8" fill="#050a10" opacity=".7"/><g fill="none" stroke="#b4b9a6" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>'
 (ROOT/'assets/items'/(name+'.svg')).write_text(svg)
