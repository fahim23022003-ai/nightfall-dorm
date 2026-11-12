"""Original Gothic Industrial material/facade illustrations; standard library only."""
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'assets/visual_identity'
root.mkdir(exist_ok=True)
colors={'dorm':('#484844','#59574e'),'hospital':('#526060','#68716a'),'hotel':('#49404b','#61565c'),'lab':('#35484c','#4a5b5c'),'mansion':('#483e3b','#63534a')}
for theme,(base,light) in colors.items():
 parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="{light}"/><stop offset="1" stop-color="{base}"/></linearGradient></defs><path fill="url(#g)" d="M0 0h256v256H0z"/>']
 for i in range(8):
  y=i*32
  parts.append(f'<path d="M0 {y}h256M{(i%3)*75+23} {y}v32" stroke="#202629" opacity=".45"/>')
  for j in range(5):
   x=(i*43+j*53)%256
   parts.append(f'<path d="m{x} {y+8} 21 -1m-16 5 31 0" stroke="{light}" opacity=".25"/>')
 parts.append('<path d="m24 30 11 18-7 12 19 18m178 45-17 10 5 17-12 11" fill="none" stroke="#252930" opacity=".6"/><ellipse cx="175" cy="210" rx="32" ry="14" fill="#292b2b" opacity=".2"/></svg>')
 (root/(theme+'_floor.svg')).write_text(''.join(parts))
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720"><defs><linearGradient id="night" x2="0" y2="1"><stop stop-color="#11131d"/><stop offset="1" stop-color="#080e14"/></linearGradient><radialGradient id="moon"><stop stop-color="#b5c7cc" stop-opacity=".2"/><stop offset="1" stop-color="#8a9cae" stop-opacity="0"/></radialGradient><linearGradient id="wall"><stop stop-color="#30343b"/><stop offset="1" stop-color="#131922"/></linearGradient></defs><path fill="url(#night)" d="M0 0h1280v720H0z"/><circle fill="url(#moon)" cx="1080" cy="150" r="310"/><circle fill="#75848c" opacity=".28" cx="1090" cy="110" r="55"/>']
parts.append('<path d="M680 600V180l80-53 90 26 100-98 125 107 111-9 83 61v386Z" fill="url(#wall)" stroke="#4b4b51" stroke-width="3"/><path d="m811 189 141-120 148 121M690 216h576M698 580h560" fill="none" stroke="#777064" stroke-width="3" opacity=".5"/>')
for x in [726,804,1037,1147]:
 for y in [226,350]:
  parts.append(f'<path d="M{x} {y+75}v-49q0-26 24-38 24 12 24 38v49Z" fill="#0b111c" stroke="#575458" stroke-width="4"/><path d="M{x+24} {y-7}v81m-23-43h45m-38-35 20 24-12 18 24 15" stroke="#86929b" stroke-width="1" opacity=".35"/>')
for x in range(700,1260,27):
 parts.append(f'<path d="M{x} 220v350" stroke="#090e16" opacity=".18"/><path d="M{x+2} 220v350" stroke="#59606a" opacity=".12"/>')
for x,y in [(763,275),(1080,365),(1172,450),(865,215)]:
 parts.append(f'<path d="M{x} {y}v84l-7 26 3 44" fill="none" stroke="#141b20" stroke-width="9" opacity=".55"/>')
parts.append('<path d="M905 600V392q45-65 90 0v208Z" fill="#090d16" stroke="#6a6359" stroke-width="6"/><path d="M950 360v240m-45-128h90" stroke="#71675b" stroke-width="4"/><path d="M690 570h555l35 150H610Z" fill="#161d24"/><path d="M670 600h598m-570 40h560m-190-36-8 110" stroke="#494846" opacity=".5"/>')
for x in [704,1233]:
 parts.append(f'<path d="M{x} 235v335h-22" fill="none" stroke="#514c48" stroke-width="9"/><path d="M{x-8} 276h16m-16 155h16" stroke="#93816b" stroke-width="4"/>')
parts.append('<path d="M620 720 600 390 570 325m30 100 65-70m-10 365 18-360 35-53" fill="none" stroke="#080e14" stroke-width="12"/></svg>')
(root/'menu_facade.svg').write_text(''.join(parts))
