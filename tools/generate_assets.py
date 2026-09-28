"""Original vector illustrations and synthesized audio; no external assets."""
from pathlib import Path
import math, wave, struct, random
ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'assets/symbols';A.mkdir(parents=True,exist_ok=True)
head='<svg xmlns="http://www.w3.org/2000/svg" width="180" height="140" viewBox="0 0 180 140"><g stroke="#273b46" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">'
def svg(n,body): (A/f'{n}.svg').write_text(head+body+'</g></svg>')
svg(0,'<g transform="rotate(-24 90 70)" fill="#fff0c7"><path d="M48 54 C20 27 17 66 36 70 C14 89 41 112 53 89 L126 89 C146 112 168 87 147 72 C170 54 144 30 128 54 Z"/><path d="M60 65 H116" stroke="#dec58e"/></g>')
svg(1,'<circle cx="90" cy="70" r="47" fill="#c0dd50"/><path d="M54 40 Q110 56 114 111 M68 30 Q70 84 133 91" fill="none" stroke="#fffbcf" stroke-width="7"/>')
svg(2,'<g fill="#db9d80"><path d="M54 101 Q51 83 72 73 Q91 46 107 72 Q133 81 128 104 Q117 122 91 109 Q62 121 54 101Z"/><ellipse cx="43" cy="63" rx="13" ry="18" transform="rotate(-25 43 63)"/><ellipse cx="73" cy="40" rx="13" ry="18"/><ellipse cx="107" cy="39" rx="13" ry="18"/><ellipse cx="139" cy="62" rx="13" ry="18" transform="rotate(25 139 62)"/></g>')
svg(3,'<ellipse cx="90" cy="62" rx="56" ry="17" fill="#233f4d"/><path d="M34 62 L22 102 Q90 125 158 102 L146 62 Q90 91 34 62Z" fill="#6ac9c0"/><ellipse cx="90" cy="91" rx="17" ry="12" fill="#fff0c7"/><path d="M48 56 Q90 40 131 57" stroke="#c49766" stroke-width="10"/>')
def dog(husky=False,color=None):
 c=color or ('#93b3c9' if husky else '#b87040');ear='#526a80' if husky else '#69422e'
 return f'''<path d="M35 90 Q8 74 20 59" fill="none" stroke="{c}" stroke-width="12"/><rect x="32" y="71" width="101" height="39" rx="20" fill="{c}"/><path d="M45 104 V121 H61 V102 M100 104 V121 H116 V102" fill="{c}"/><path d="M112 54 L111 20 L133 37 L154 25 L160 65" fill="{ear}"/><ellipse cx="134" cy="65" rx="31" ry="34" fill="{c}"/>'''+('''<path d="M111 48 L133 62 L153 47 L158 78 Q136 99 113 78Z" fill="#f5f9ef"/>''' if husky else '''<ellipse cx="111" cy="66" rx="13" ry="28" fill="#69422e"/>''')+f'''<ellipse cx="146" cy="78" rx="23" ry="14" fill="{'#fffdf0' if husky else '#eabb7d'}"/><circle cx="126" cy="61" r="5" fill="{'#55c9f3' if husky else '#273b46'}"/><circle cx="148" cy="60" r="5" fill="{'#55c9f3' if husky else '#273b46'}"/><ellipse cx="158" cy="75" rx="7" ry="5" fill="#273b46"/><path d="M139 89 Q144 106 151 89" fill="#f69b9b"/><path d="M110 92 L128 97" stroke="#e56e61" stroke-width="8"/>'''
svg(4,dog().replace('<path d="M112 54 L111 20 L133 37 L154 25 L160 65" fill="#69422e"/>',''));svg(5,dog(True).replace('x="32" y="71" width="101"','x="65" y="71" width="68"').replace('M35 90 Q8 74 20 59','M68 90 Q40 74 51 59').replace('M45 104 V121 H61 V102','M72 104 V121 H88 V102'))
svg(6,'<path d="M36 49 Q21 25 44 26 L66 42 H119 L142 25 Q164 23 147 49 V94 Q166 120 142 117 L120 102 H65 L42 119 Q20 119 35 94Z" fill="#f1c45b"/><g fill="#be8848" stroke="none"><circle cx="61" cy="65" r="4"/><circle cx="91" cy="87" r="4"/><circle cx="121" cy="65" r="4"/></g><path d="M86 50 L92 63 L106 65 L96 75 L98 88 L85 81 L73 88 L75 74 L65 65 L80 63Z" fill="#fff0b0"/>')
svg(7,'<path d="M36 65 H144 V120 H36Z" fill="#d68e65"/><path d="M19 67 L90 16 L161 67 L151 80 L90 37 L29 80Z" fill="#d36055"/><path d="M69 120 V90 A21 21 0 0 1 111 90 V120Z" fill="#403e41"/><path d="M47 78 H58 M124 78 H136" stroke="#f4c591"/>')
svg(8,'<path d="M90 10 L103 32 L132 19 L134 47 L167 59 L145 80 L159 106 L128 109 L111 132 L87 114 L58 131 L50 105 L19 99 L34 73 L17 46 L51 41 L61 14Z" fill="#e3c4f4" stroke="#8965a7"/>'+dog(False,'#f4dbb0'))
svg(9,'<ellipse cx="90" cy="58" rx="56" ry="28" fill="none" stroke="#6299b7" stroke-width="16"/><path d="M83 77 V88" stroke="#f0c35c" stroke-width="8"/><path d="M90 83 L114 99 L106 124 H74 L66 99Z" fill="#f0c35c"/><path d="M82 101 L88 108 L101 96" fill="none" stroke="#fff5c8"/>')
svg(10,'<circle cx="90" cy="70" r="55" fill="#f5d8df" stroke="#ce718f"/><g transform="translate(27 23) scale(.7) rotate(-20 90 70)" fill="#fff8e0"><path d="M48 54 C20 27 17 66 36 70 C14 89 41 112 53 89 L126 89 C146 112 168 87 147 72 C170 54 144 30 128 54 Z"/></g><path d="M90 29 V42 M84 35 H96 M125 98 V111 M119 104 H131" stroke="#ce718f"/>')
for i,c in enumerate(['#e8bd68','#c69b70','#d99656','#c39a67','#947257','#e9d7be']): svg('dog'+str(i+2),dog(False,c))
# Synthesize warm, quiet, original melodies/effects. Deterministic PCM, no recordings.
rate=22050; dest=ROOT/'assets/audio';dest.mkdir(exist_ok=True)
def write(name,notes,beat=.14,volume=.23):
 samples=[]
 for freq in notes:
  for i in range(int(rate*beat)):
   t=i/rate;env=min(1,t/.012)*max(0,1-t/beat)**1.8
   value=(math.sin(2*math.pi*freq*t)+.2*math.sin(4*math.pi*freq*t))*env*volume if freq else 0
   samples.append(int(max(-1,min(1,value))*32767))
 with wave.open(str(dest/(name+'.wav')),'w') as w:w.setparams((1,2,rate,0,'NONE',''));w.writeframes(struct.pack('<'+'h'*len(samples),*samples))
write('click',[600],.05,.12);write('stop',[330,440],.045,.13);write('spin',[180,220,260,220],.075,.08)
write('small',[523,659,784]);write('medium',[392,523,659,784,1047]);write('big',[523,659,784,1047,784,1047],.12)
write('jackpot',[392,523,659,784,1047,1319,1047,1568],.16)
write('bark',[160,230,150,0,190,260,170],.06,.14);write('howl',[260,290,330,370,392,392,370,330],.13,.10)
write('bonus',[659,784,659,1047],.15);write('free',[784,659,523,659,784,1047,784,659],.22,.12)
write('meadow',[262,330,392,330,294,349,440,349,262,330,392,523,440,392,330,0],.45,.085)
write('snow',[220,330,440,330,247,370,494,370,262,392,523,392,247,330,440,0],.55,.08)
