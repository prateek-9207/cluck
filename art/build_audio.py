"""Original synthesized audio, no external samples."""
import math, wave, struct, random
from pathlib import Path
OUT=Path(__file__).resolve().parents[1]/'assets/audio'
RATE=22050
random.seed(42)
def write(name,samples):
    with wave.open(str(OUT/(name+'.wav')),'wb') as w:
        w.setparams((1,2,RATE,0,'NONE','not compressed'));w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x)) * 26000)) for x in samples))
for name,freq,duration in [('egg',570,.07),('gem',1100,.07),('tap',420,.08),('hurt',110,.2),('sweep',220,.14),('boom',65,.3),('heal',660,.4),('level',880,.55),('boss',90,.7),('win',740,.7),('lose',150,.5)]:
    samples=[]
    for i in range(int(RATE*duration)):
        t=i/RATE;env=(1-t/duration)**2
        pitch=freq*(1+t*1.8 if name in ['heal','level','win','gem'] else 1-t*.6)
        s=math.sin(2*math.pi*pitch*t)*.45
        if name in ['boom','sweep','hurt']:s+=random.uniform(-.2,.2)
        samples.append(s*env)
    write(name,samples)
# 16 second pastoral plucked loop at 120bpm, C / Am / F / G.
notes=[48,52,55,60,45,52,57,60,41,48,53,57,43,50,55,59]
samples=[0.]*(RATE*16)
for beat in range(32):
    base=notes[(beat//8)*4]; note=notes[(beat//8)*4+beat%4]+12;f=440*2**((note-69)/12)
    for i in range(int(RATE*.65)):
        t=i/RATE;idx=int(beat*.5*RATE)+i
        if idx<len(samples):samples[idx]+=(math.sin(2*math.pi*f*t)+.3*math.sin(4*math.pi*f*t))*math.exp(-t*9)*.19
    if beat%2==0:
        f=440*2**((base-69)/12)
        for i in range(int(RATE*.45)):
            t=i/RATE;idx=int(beat*.5*RATE)+i
            if idx<len(samples):samples[idx]+=math.sin(2*math.pi*f*t)*math.exp(-t*7)*.20
write('farm_loop',samples)
