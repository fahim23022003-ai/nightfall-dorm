#!/usr/bin/env python3
"""Original Nightfall Dorm vector illustrations; no external art source."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
r=ROOT/'assets/wrath';r.mkdir(exist_ok=True)
shapes={
'flame':('<path d="M20 63L21 42 32 34 36 17 46 17 49 32 61 39 61 61Z" fill="#633c39"/><path d="M37 35L28 19 31 8 39 18 45 5 53 20 48 35Z" fill="#ed7850"/><path d="M37 31L39 20 44 16 47 28 43 36Z" fill="#ffda80"/><path d="M20 46L63 46 59 54 25 54Z" fill="#be955d"/>','#ed8754'),
'frost':('<path d="M26 62L28 37 23 27 39 4 55 27 50 37 53 62Z" fill="#3b566a"/><path d="M39 6L24 27 38 43 54 27Z" fill="#8bdfec"/><path d="M39 7L39 40 54 27Z" fill="#c8fcff"/><path d="M20 50L59 50 66 63 15 63Z" fill="#718397"/><path d="M18 18L29 23M56 16L49 22M39 47L39 61" stroke="#d4fbff" stroke-width="3"/>','#8bdfe8'),
'shock':('<path d="M12 54L22 37 58 37 68 54 58 65 21 65Z" fill="#3b3750"/><path d="M18 51L26 43 54 43 61 51 54 58 25 58Z" fill="#8f79b3"/><path d="M42 8L27 34 38 32 34 49 54 23 43 26Z" fill="#e2d786"/><path d="M22 41L17 29M59 41L64 29" stroke="#b1a5e7" stroke-width="5"/>','#c1a4ea'),
'auto_repair':('<path d="M18 64L18 32 27 24 53 24 62 32 62 64Z" fill="#435c59"/><path d="M24 38L56 38 56 58 24 58Z" fill="#9ec5ac"/><path d="M37 40L44 40 44 45 49 45 49 52 44 52 44 57 37 57 37 52 31 52 31 45 37 45Z" fill="#335748"/><path d="M23 24L19 15 26 10 34 19M56 24L60 15 53 10 45 19" stroke="#b2c9b4" stroke-width="5" fill="none"/>','#9ed4ad'),
'shield':('<path d="M18 63L23 47 24 27 40 18 56 27 57 47 62 63Z" fill="#3b4d69"/><path d="M40 7L19 18 23 39Q27 51 40 57Q54 51 58 39L62 18Z" fill="#74a9cf" stroke="#bddef1" stroke-width="3"/><path d="M40 15L29 22 32 38 40 46 49 37 52 23Z" fill="#406584"/><path d="M38 18L38 42M30 29L49 29" stroke="#a4e6fa" stroke-width="3"/>','#81bce6'),
'decoy':('<path d="M17 65L24 55 26 38 54 38 57 55 64 65Z" fill="#4c3d58"/><circle cx="40" cy="27" r="15" fill="#c8a5bb"/><path d="M28 23L32 16 48 16 53 23 48 35 32 35Z" fill="#705473"/><circle cx="34" cy="25" r="3" fill="#f3b3d4"/><circle cx="47" cy="25" r="3" fill="#f3b3d4"/><path d="M40 4L40 11M15 20L23 23M58 23L67 19" stroke="#d49ec5" stroke-width="3"/><path d="M29 45L51 45M25 54L55 54" stroke="#bda5bd" stroke-width="3"/>','#d49bc5')}
for key,(shape,color) in shapes.items():
 (r/(key+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80"><ellipse cx="40" cy="69" rx="32" ry="8" fill="#121621" opacity=".7"/>'+shape+'<path d="M12 68L68 68" stroke="#827266" stroke-width="3"/></svg>')
branches=['searing','wildfire','deep_chill','rime_field','capacitor_burst','rapid_discharge','efficient_mending','emergency_protocol','aegis_burst','steady_veil','force_lure','faint_echo']
for i,branch in enumerate(branches):
 kind=list(shapes)[i//2];shape,color=shapes[kind]
 mark='<path d="M12 66L40 53 68 66" stroke="'+color+'" stroke-width="5" fill="none"/>' if i%2 else '<path d="M30 69L40 54 50 69" stroke="'+color+'" stroke-width="5" fill="none"/>'
 (ROOT/'assets'/'premium_ui'/(branch+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80">'+shape+mark+'</svg>')
