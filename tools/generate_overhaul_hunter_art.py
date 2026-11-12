"""Original Nightfall Dorm vector character plates; no third-party artwork.
Each plate is selected by the real gameplay animation state. SVG coordinate
space is80x100; silhouette and weapon identities remain readable at game scale.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/hunters'
STATES=['idle','walk','attack','hurt','defend','special','death']
PALETTE={'crusher':'#d1ad79','stalker':'#b8abea','ravager':'#ef8390','witch':'#bca2ee','electric':'#85e4eb','storm':'#e4cc8c'}
for kind,glow in PALETTE.items():
 for state in STATES:
  attack=state=='attack';special=state=='special';defend=state=='defend'
  sway=5 if state=='walk' else 0
  angle=-14 if attack else 12 if state=='hurt' else 0
  motion='translate(6 13) rotate(24 35 60)' if state=='death' else f'rotate({angle} 38 57)'
  ink='#151722';cloth='#302638';edge='#827184'
  eye=f'<path d="M27 29L35 31L32 35Z M42 31L50 28L46 35Z" fill="{glow}"/>'
  mouth='<path d="M31 40L35 43L39 40L43 43L47 39" fill="none" stroke="#ead5bf" stroke-width="2"/>'
  weapon_angle=-34 if attack else -15 if special else 0
  fx=f'<circle cx="39" cy="46" r="34" fill="none" stroke="{glow}" stroke-width="2" stroke-dasharray="4 8"/>' if special else ''
  legs=f'<path d="M25 71L{22-sway} 93H34L37 73M43 73L{45+sway} 93H58L52 70" fill="#282736" stroke="{edge}" stroke-width="2"/>'
  if kind=='crusher':
   # Broad shoulders, heavy jaw, block-like armour and a massive cracked maul.
   body=f'<path d="M17 36L59 36L66 70L53 81L27 82L13 66Z" fill="#4e4542" stroke="{ink}" stroke-width="3"/><path d="M10 38L22 31L31 43L25 54L9 50Z M52 34L66 31L74 43L65 54L53 48Z" fill="#797164" stroke="{glow}" stroke-width="2"/><path d="M12 36L8 25L22 33M63 33L70 23L69 40" fill="#c2ae8b" stroke="{ink}" stroke-width="2"/><path d="M29 52L52 49L55 67L34 71Z" fill="#34343c" stroke="{glow}" stroke-width="2"/>'
   head=f'<path d="M23 13L31 17L38 9L47 15L55 12L56 35L49 49L27 47L20 30Z" fill="#66605b" stroke="{ink}" stroke-width="3"/>{eye}<path d="M27 37L51 36L48 48L32 49Z" fill="#b9a996" stroke="{ink}" stroke-width="2"/><path d="M32 39V45M39 39V46M46 39V44" stroke="#3e3541" stroke-width="2"/>'
   weapon=f'<g transform="rotate({weapon_angle} 62 68)"><path d="M61 33L65 88" stroke="#98775b" stroke-width="6"/><path d="M48 17L71 13L78 38L54 45Z" fill="#7e7b77" stroke="{ink}" stroke-width="3"/><path d="M62 17L59 28L66 31L62 42" fill="none" stroke="{glow}" stroke-width="2"/></g>'
  elif kind=='stalker':
   # Long expressionless porcelain mask, narrow body and trailing cut ribbons.
   body=f'<path d="M27 39L49 39L56 73L45 84L39 70L30 88L19 75Z" fill="#302a44" stroke="{edge}" stroke-width="2"/><path d="M26 44L8 55L5 76L18 64M49 44L65 51L75 69L61 61" fill="none" stroke="#635379" stroke-width="6"/><path d="M24 53L10 88L22 78L18 98M49 54L67 86L58 76L67 96" fill="none" stroke="#75608d" stroke-width="3"/>'
   head=f'<path d="M21 22Q39 1 56 22L49 42L38 56L26 40Z" fill="#d2cfcb" stroke="{ink}" stroke-width="3"/><path d="M22 21L37 11L55 22L47 15L38 5L27 11Z" fill="#282239"/><path d="M28 29L35 33M48 29L42 33" stroke="{glow}" stroke-width="3"/><path d="M38 36V47M31 17L34 24L30 28" stroke="#62546b" stroke-width="2"/>'
   weapon=f'<g transform="rotate({weapon_angle} 64 60)"><path d="M64 50L74 78L62 68L58 51Z M10 57L2 83L15 71L17 57Z" fill="#b6c1d4" stroke="{ink}" stroke-width="2"/></g>'
  elif kind=='ravager':
   # Lean beast, swept ears, four exaggerated claws and a hooked tail.
   body=f'<path d="M26 37L52 36L60 64L49 81L27 78L17 58Z" fill="#4b2936" stroke="{glow}" stroke-width="2"/><path d="M24 46L9 53L4 69M54 43L68 49L75 64" fill="none" stroke="#93616b" stroke-width="8"/><path d="M19 70Q-4 78 7 94Q19 90 15 83" fill="none" stroke="#aa687b" stroke-width="5"/><path d="M31 47L38 56L45 47L49 64L34 67Z" fill="#9a5d68"/>'
   head=f'<path d="M22 25L9 5L31 17L43 12L65 2L55 26L54 42L40 51L25 43Z" fill="#69505a" stroke="{ink}" stroke-width="3"/>{eye}<path d="M27 37L50 36L44 49L31 46Z" fill="#211c28"/><path d="M30 38L32 44L35 38M43 38L44 44L47 37" fill="#eadbca"/>'
   weapon='<path d="M2 61L8 82L11 63M8 58L17 78L17 58M65 55L68 79L73 57M72 56L77 75L79 52" fill="#e5c4b8" stroke="#402635" stroke-width="2"/>'
  elif kind=='witch':
   # Oversized crooked hat, wide shoulder mantle, layered skirt and crooked staff.
   legs=''
   body=f'<path d="M21 42L56 40L67 54L53 58L62 91L48 86L41 96L33 84L18 92L24 58L9 55Z" fill="#402e56" stroke="{edge}" stroke-width="2"/><path d="M24 45L40 57L56 44L50 65L32 69Z" fill="#79568d"/><path d="M32 65L26 89M44 67L49 88" stroke="#ae83bf" stroke-width="2"/>'
   head=f'<path d="M23 25Q39 13 54 27L49 44L37 49L25 40Z" fill="#7b6c86" stroke="{ink}" stroke-width="2"/>{eye}{mouth}<path d="M4 30L23 19L31 5L51 1L45 10L52 23L74 29L56 36L21 35Z" fill="#332641" stroke="{glow}" stroke-width="2"/><path d="M24 22L50 23L55 28L20 27Z" fill="#8d5c93"/><path d="M33 5L43 7L38 15" fill="none" stroke="#9c82ad" stroke-width="2"/>'
   weapon=f'<g transform="rotate({weapon_angle} 67 68)"><path d="M65 92L62 40L72 22L65 13" fill="none" stroke="#b0a1a8" stroke-width="4"/><path d="M64 12L72 19L62 33L56 24Z" fill="#c0a4f0" stroke="#503b68" stroke-width="2"/><circle cx="64" cy="23" r="4" fill="#f4e8ff"/></g>'
  elif kind=='electric':
   # Angular conductor torso with open gaps, external coils and a fork weapon.
   legs=f'<path d="M25 75L19 87L29 94L35 81M48 74L56 85L48 95L43 82" fill="#395c6e" stroke="{glow}" stroke-width="2"/>'
   body=f'<path d="M25 41L52 39L60 56L49 62L55 74L41 82L27 74L32 61L18 55Z" fill="#29495d" stroke="{glow}" stroke-width="2"/><path d="M31 46L47 47L51 55L40 64L29 55Z" fill="#1b2738"/><path d="M37 45L33 55L41 53L37 64L49 49L41 51Z" fill="#c0ffff"/><path d="M17 37L9 43L10 57M59 36L68 42L67 57" stroke="#4b8297" stroke-width="7" fill="none"/><path d="M4 35H18M4 40H18M4 45H18M62 34H76M62 39H76M62 44H76" stroke="#9bd9df" stroke-width="3"/>'
   head=f'<path d="M24 18L53 17L57 35L47 46L28 44L20 31Z" fill="#526875" stroke="{ink}" stroke-width="3"/>{eye}<path d="M28 16L21 4M39 16L39 1M50 16L57 3" stroke="#9ce9ef" stroke-width="3"/><circle cx="21" cy="4" r="3" fill="#d8ffff"/><circle cx="39" cy="3" r="3" fill="#d8ffff"/><circle cx="57" cy="4" r="3" fill="#d8ffff"/><path d="M29 38H48" stroke="#b5f7f0" stroke-width="2"/>'
   weapon=f'<g transform="rotate({weapon_angle} 68 67)"><path d="M67 91V54L57 44V28M67 54L76 44V28M67 50V24" fill="none" stroke="#a5dce2" stroke-width="4"/><path d="M58 22L53 31H61M68 18L63 27H71M76 23L72 32H80" fill="{glow}"/></g>'
  else:
   # Floating hollow-faced wraith, broad storm halo and lightning arms.
   legs=''
   body=f'<path d="M23 41L53 41L64 64L72 84L55 76L49 98L40 79L29 94L25 75L8 85L17 61Z" fill="#34334d" stroke="{glow}" stroke-width="2"/><path d="M25 47L39 58L54 47L48 70L36 66L27 79Z" fill="#6d6382"/><path d="M24 47L11 52L15 62L3 72M54 45L69 53L64 64L77 74" fill="none" stroke="#f0d995" stroke-width="4"/>'
   head=f'<ellipse cx="39" cy="23" rx="30" ry="21" fill="none" stroke="#9e88b0" stroke-width="3"/><path d="M9 24L2 18L12 14M65 16L76 11L72 24M25 4L29 0M51 4L56 0" fill="none" stroke="{glow}" stroke-width="3"/><path d="M26 19Q39 9 53 20L49 38L40 48L28 39Z" fill="#2a263d" stroke="#b7a6b1" stroke-width="2"/>{eye}<path d="M37 38L40 42L44 36" fill="none" stroke="#f0d9b3" stroke-width="2"/>'
   weapon='<path d="M6 68L1 81L12 78L7 94L24 73L14 76L18 65M69 64L60 80L71 77L65 94L79 74L72 76L77 64" fill="#f0d998" stroke="#5e4d6e" stroke-width="1"/>'
  guard=f'<path d="M10 42Q39 22 67 43L58 70L38 85L16 67Z" fill="none" stroke="{glow}" stroke-width="3"/>' if defend else ''
  plate=f'<svg xmlns="http://www.w3.org/2000/svg" width="80" height="100" viewBox="0 0 80 100">{fx}<g transform="{motion}" opacity="{.55 if state=="death" else 1}">{legs}{body}{head}{weapon}{guard}</g></svg>'
  (ROOT/f'{kind}_{state}.svg').write_text(plate)
