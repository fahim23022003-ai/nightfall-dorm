from pathlib import Path
root=Path(__file__).resolve().parents[2]/"assets"/"items"
shapes={
"barricade":('<path d="M19 22h58v56H19z" fill="#586879" stroke="#dae6ec" stroke-width="4"/><path d="M22 34h52M22 64h52M34 24v52M62 24v52" stroke="#9db1c6" stroke-width="5"/><circle cx="48" cy="48" r="9" fill="#d6e4ec"/>',"BAC9DA"),
"feather":('<path d="M24 78Q26 22 72 14Q84 57 24 78" fill="#e7b446" stroke="#ffedac" stroke-width="3"/><path d="M26 76L67 25M36 61l-3-18m13 7 16-1M48 47l-2-17" stroke="#fff1c4" stroke-width="3"/>',"FFD97C"),
"inferno":('<path d="M48 12Q80 44 70 69Q52 90 28 70Q12 53 36 31Q33 52 42 54Q53 39 48 12" fill="#ec603d" stroke="#ffc17c" stroke-width="3"/><path d="M48 45Q70 68 49 78Q30 71 48 45" fill="#ffe4a5"/>',"FF9255"),
"pillow":('<path d="M17 28Q46 19 78 28L73 72Q45 83 20 72Z" fill="#bd8a37" stroke="#ffe29b" stroke-width="4"/><path d="M27 36Q47 29 67 36L63 64H30Z" fill="#f5d778"/><path d="M49 37l5 10 11 1-9 8 2 11-10-6-10 5 2-11-8-8 12-1Z" fill="#fff5c9"/>',"F9D269"),
"coupon":('<path d="M15 27h66v16q-13 6 0 13v18H15V56q13-7 0-13Z" fill="#397e70" stroke="#b2f4d3" stroke-width="3"/><path d="M32 66l32-31" stroke="#e7fff0" stroke-width="6"/><circle cx="34" cy="37" r="7" fill="none" stroke="#e7fff0" stroke-width="4"/><circle cx="63" cy="65" r="7" fill="none" stroke="#e7fff0" stroke-width="4"/>',"93E3CB"),
"decoy":('<circle cx="48" cy="31" r="17" fill="#b99cc9" stroke="#f0c4fa" stroke-width="3"/><path d="M37 46l-14 34h50L60 46" fill="#664b7f" stroke="#d4b0ed" stroke-width="3"/><path d="M35 31l8-5m12 0 8 5M44 40h9M22 57l15 7m23 0 17-7" stroke="#372c45" stroke-width="4"/><circle cx="41" cy="32" r="3" fill="#ff7eae"/><circle cx="57" cy="32" r="3" fill="#ff7eae"/>',"E2AAF2"),
"rescue":('<path d="M34 18h28v62H34Z" fill="#357f73" stroke="#b8ffe0" stroke-width="3"/><path d="M18 34h62v28H18Z" fill="#70d3bc"/><path d="M21 26Q48 7 75 26M11 17Q48-5 85 17" stroke="#baffdf" fill="none" stroke-width="3"/><path d="M42 34h12v10h10v12H54v10H42V56H32V44h10Z" fill="#e5fff4"/>',"82F1D5"),
"smoke":('<path d="M18 72Q8 55 27 48Q19 26 41 28Q48 7 65 27Q88 30 77 51Q94 69 74 79H25Z" fill="#754990" stroke="#d5a0eb" stroke-width="3"/><path d="M24 67Q50 46 68 66M38 42Q58 27 63 44" fill="none" stroke="#c994e2" stroke-width="5"/>',"C89AF4")}
for name,(body,color) in shapes.items():
 (root/(name+".svg")).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96"><rect x="3" y="3" width="90" height="90" rx="21" fill="#162939" stroke="#{color}" stroke-width="3"/>{body}</svg>')
