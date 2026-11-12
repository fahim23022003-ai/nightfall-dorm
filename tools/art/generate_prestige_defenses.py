"""Original transparent mechanical armor overlays for existing turret artwork."""
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'assets/defenses'
for kind in ['turret','heavy']:
 for level in range(5,11):
  color='F0CD78' if level==10 else 'B7A0F2' if kind=='heavy' or level>=7 else '81DDE7'
  plates='<path d="M8 32 15 28 20 35 18 52 8 49zM46 34 55 29 60 47 48 53z" fill="#314657" stroke="#8095AA" stroke-width="2"/>'
  plates+=f'<path d="M10 39 17 37M11 44l6-2M50 39l7-2M51 44l6-2" stroke="#{color}" stroke-width="3"/>'
  if level>=7:plates+=f'<path d="M9 31 4 15 17 25M51 31l7-17-1 22" fill="#405569" stroke="#{color}" stroke-width="2"/>'
  for i in range(level-4):plates+=f'<circle cx="{19+i*5}" cy="56" r="1.6" fill="#{color}"/>'
  if level==10:plates+=f'<path d="m20 14-2-10 9 6 5-8 5 8 9-6-2 10z" fill="#{color}" stroke="#7D603A" stroke-width="1.5"/>'
  (root/f'{kind}_{level}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">{plates}</svg>')
