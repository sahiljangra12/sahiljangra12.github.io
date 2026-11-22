from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import glob, sys
W,H=1200,630
R='/home/claude/sahiljangra12.github.io/'
order=['grid-data-centers','asda-lab','charm-city-pulse','baltimore-heat','neural','billback','krishi','global','policy','basket','street','tree','climate','four','thesis','planet','energy','sdg','claimback','blue','search']
files=sorted(glob.glob(R+'docs/assets/posters/thumbs/*.webp'))
def rank(f):
    n=f.split('/')[-1]
    for i,k in enumerate(order):
        if k in n: return i
    return 99
files=sorted(files,key=rank)
# --- poster wall, tilted
tw,th,gap=300,169,14
cols,rows=7,7
wall=Image.new('RGB',(cols*(tw+gap),rows*(th+gap)),(7,8,12))
k=0
for r in range(rows):
    off=-(tw//2) if r%2 else 0
    for c in range(cols+1):
        im=Image.open(files[k%len(files)]).convert('RGB').resize((tw,th),Image.LANCZOS); k+=1
        m=Image.new('L',(tw,th),0); ImageDraw.Draw(m).rounded_rectangle([0,0,tw-1,th-1],radius=14,fill=255)
        wall.paste(im,(off+c*(tw+gap),r*(th+gap)),m)
wall=wall.rotate(9,resample=Image.BICUBIC,expand=False)
cx,cy=wall.width//2,wall.height//2
bg=wall.crop((cx-W//2,cy-H//2,cx+W//2,cy+H//2))
bg=ImageEnhance.Brightness(bg).enhance(0.92)
# darken toward the middle band where the card sits, keep edges lively
shade=Image.new('L',(W,H),0); sd=ImageDraw.Draw(shade)
sd.rounded_rectangle([420,150,W-150,H-140],radius=90,fill=150); shade=shade.filter(ImageFilter.GaussianBlur(70))
bg=Image.composite(Image.new('RGB',(W,H),(4,5,9)),bg,shade)
# --- glass card
card=[78,96,W-78,H-96]
blur=bg.filter(ImageFilter.GaussianBlur(5)); blur=ImageEnhance.Brightness(blur).enhance(0.78)
cm=Image.new('L',(W,H),0); ImageDraw.Draw(cm).rounded_rectangle(card,radius=54,fill=255)
sh=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(sh).rounded_rectangle([card[0],card[1]+14,card[2],card[3]+14],radius=54,fill=(0,0,0,150)); sh=sh.filter(ImageFilter.GaussianBlur(26))
bg=Image.alpha_composite(bg.convert('RGBA'),sh).convert('RGB')
bg=Image.composite(blur,bg,cm)
ov=Image.new('RGBA',(W,H),(0,0,0,0)); od=ImageDraw.Draw(ov)
od.rounded_rectangle(card,radius=54,fill=(255,255,255,16),outline=(255,255,255,170),width=2)
bg=Image.alpha_composite(bg.convert('RGBA'),ov).convert('RGB')
# top rim highlight
hl=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(hl).arc([card[0],card[1],card[2],card[1]+108],180,360,fill=(255,255,255,0))
F='/usr/share/fonts/opentype/inter/'; f=lambda n,s:ImageFont.truetype(F+n,s)
# --- photo
P=320; px,py=122,(H-P)//2
ph=Image.open('/mnt/user-data/uploads/a689f864-image.png').convert('RGB').crop((60,0,740,680)).resize((P,P),Image.LANCZOS)
S=4; m=Image.new('L',(P*S,P*S),0); ImageDraw.Draw(m).ellipse([0,0,P*S-1,P*S-1],fill=255); m=m.resize((P,P),Image.LANCZOS)
ring=Image.new('RGBA',(W,H),(0,0,0,0)); rd=ImageDraw.Draw(ring)
rd.ellipse([px-9,py-9,px+P+9,py+P+9],fill=(122,162,255,80)); rd.ellipse([px-3,py-3,px+P+3,py+P+3],fill=(255,255,255,170))
bg=Image.alpha_composite(bg.convert('RGBA'),ring).convert('RGB'); bg.paste(ph,(px,py),m)
# --- logo
lg=Image.open(R+'docs/__l5e/assets-v1/df5f9724-793f-4e03-97f3-1cb83b47769d/sahil-lab-logo.png').convert('RGBA')
a=lg.split()[3]; a=a.crop(a.point(lambda v:255 if v>40 else 0).getbbox()); lw=380; lh=int(a.height*lw/a.width); a=a.resize((lw,lh),Image.LANCZOS)
stops=[(0,(251,251,253)),(.22,(201,204,211)),(.44,(164,169,178)),(.52,(238,240,244)),(.68,(154,160,170)),(.84,(131,136,145)),(1,(217,220,226))]
grad=Image.new('RGB',(lw,lh)); gd=ImageDraw.Draw(grad)
for y in range(lh):
    t=y/max(1,lh-1)
    for (t0,c0),(t1,c1) in zip(stops,stops[1:]):
        if t0<=t<=t1:
            u=(t-t0)/(t1-t0); col=tuple(int(c0[i]+(c1[i]-c0[i])*u) for i in range(3)); break
    gd.line([(0,y),(lw,y)],fill=col)
x=496; ly=116
s2=Image.new('RGBA',(W,H),(0,0,0,0)); s2.paste((0,0,0,170),(x+2,ly+5),a); s2=s2.filter(ImageFilter.GaussianBlur(5))
bg=Image.alpha_composite(bg.convert('RGBA'),s2).convert('RGB'); bg.paste(grad,(x,ly),a)
y0=ly+lh+20
ts=Image.new('RGBA',(W,H),(0,0,0,0)); td=ImageDraw.Draw(ts)
td.text((x-3,y0+3),'Sahil',font=f('InterDisplay-ExtraBold.otf',80),fill=(0,0,0,230))
td.text((x,y0+102),'Data science.',font=f('InterDisplay-Bold.otf',37),fill=(0,0,0,230))
td.text((x,y0+146),'Evidence before conclusions.',font=f('InterDisplay-Bold.otf',37),fill=(0,0,0,230))
td.text((x,y0+208),'MSE Data Science · Johns Hopkins University',font=f('Inter-Medium.otf',23),fill=(0,0,0,240))
ts=ts.filter(ImageFilter.GaussianBlur(7))
bg=Image.alpha_composite(bg.convert('RGBA'),ts); bg=Image.alpha_composite(bg,ts).convert('RGB')
d=ImageDraw.Draw(bg)
d.text((x-3,y0),'Sahil',font=f('InterDisplay-ExtraBold.otf',80),fill=(255,255,255))
d.text((x,y0+100),'Data science.',font=f('InterDisplay-Bold.otf',37),fill=(240,243,250))
d.text((x,y0+144),'Evidence before conclusions.',font=f('InterDisplay-Bold.otf',37),fill=(240,243,250))
d.text((x,y0+206),'MSE Data Science · Johns Hopkins University',font=f('Inter-Medium.otf',23),fill=(228,233,243))
t='sahiljangra12.github.io'; ft=f('Inter-SemiBold.otf',21); tw2=d.textlength(t,font=ft); py2=y0+250
pill=Image.new('RGBA',(W,H),(0,0,0,0)); pd=ImageDraw.Draw(pill)
pd.rounded_rectangle([x,py2,x+tw2+46,py2+44],radius=22,fill=(0,0,0,110),outline=(255,255,255,170),width=2)
bg=Image.alpha_composite(bg.convert('RGBA'),pill).convert('RGB'); ImageDraw.Draw(bg).text((x+23,py2+9),t,font=ft,fill=(255,255,255))
print('bottom',py2+44,'card',card)
out=sys.argv[1]; bg.save(out,optimize=True); bg.save('/tmp/shots/og.png')
