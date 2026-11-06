#!/usr/bin/env python3
"""Build original menu-bar glyphs. Maintainer-only dependency: fonttools."""
from pathlib import Path
import runpy
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.cu2quPen import Cu2QuPen

root = Path(__file__).resolve().parent.parent
status = runpy.run_path(str(root/'home/.local/bin/macos-status'))
art = {}
for level in range(11):
    for index, state in enumerate(['discharging', 'charging', 'full', 'plugged']):
        art[0xe000 + index*16 + level] = status['battery_icon']({'capacity':level*10,'connected':index!=0,'available':True,'state':state})
for index, state in enumerate(['wifi','ethernet','offline']):
    art[0xe050+index] = status['network_icon'](state)
for index, name in enumerate(['spotlight','control-center']):
    art[0xe060+index] = (root/'home/.local/share/macos-desktop/icons'/f'{name}.svg').read_text()
fb = FontBuilder(1000,isTTF=True)
order=['.notdef']+[f'uni{code:04X}' for code in art]
fb.setupGlyphOrder(order)
glyphs={'.notdef':TTGlyphPen(None).glyph()};metrics={'.notdef':(1000,0)}
for code, source in art.items():
    rawpen=TTGlyphPen(None);pen=Cu2QuPen(rawpen,1.0)
    def polygon(points):
        pen.moveTo(points[0])
        for p in points[1:]:pen.lineTo(p)
        pen.closePath()
    def rect(x,y,w,h):polygon([(x,y),(x+w,y),(x+w,y+h),(x,y+h)])
    def circle(x,y,r):
        k=.55228475*r;pen.moveTo((x+r,y));pen.curveTo((x+r,y+k),(x+k,y+r),(x,y+r));pen.curveTo((x-k,y+r),(x-r,y+k),(x-r,y));pen.curveTo((x-r,y-k),(x-k,y-r),(x,y-r));pen.curveTo((x+k,y-r),(x+r,y-k),(x+r,y));pen.closePath()
    if code<0xe050:
        level=(code-0xe000)%16;state=(code-0xe000)//16
        # Horizontal battery with a true hollow case.
        rect(60,190,1020,65);rect(60,735,1020,65);rect(30,255,65,480);rect(1045,255,65,480);rect(1150,365,65,255)
        if state==0:rect(155,310, max(1,800*level/10),375)
        elif state in [1,2]:
            rect(155,310,230,375);rect(780,310,175,375)
            polygon([(670,920),(430,470),(605,470),(535,75),(850,580),(655,580)])
        else:
            rect(155,310,160,375);rect(830,310,125,375);rect(440,430,300,200);rect(485,630,50,180);rect(650,630,50,180);rect(560,230,65,200)
        advance=1280
    elif code==0xe050:
        # Three rounded-looking Wi-Fi bands and a dot.
        for rad in [510,340,175]:
            import math
            outer=[(600+rad*__import__('math').cos(t),250+rad*__import__('math').sin(t)) for t in [__import__('math').radians(v) for v in range(42,139,4)]]
            inner=[(600+(rad-75)*__import__('math').cos(t),250+(rad-75)*__import__('math').sin(t)) for t in [__import__('math').radians(v) for v in range(138,41,-4)]]
            polygon(outer+inner)
        circle(600,230,60);advance=1200
    elif code==0xe051:
        rect(120,300,65,460);rect(185,695,770,65);rect(955,300,65,460);rect(185,300,240,65);rect(715,300,240,65);rect(425,180,290,65);rect(425,180,55,180);rect(660,180,55,180)
        for x in [350,540,730]:rect(x,530,55,170)
        advance=1150
    elif code==0xe052:
        polygon([(180,800),(240,840),(1020,180),(960,130)]);advance=1200
    elif code==0xe060:
        # Hollow magnifying glass ring, with clockwise inner contour.
        circle(460,590,310)
        # Reverse winding by reflecting the inner circular path.
        k=.55228475*225;pen.moveTo((685,590));pen.curveTo((685,590-k),(460+k,365),(460,365));pen.curveTo((460-k,365),(235,590-k),(235,590));pen.curveTo((235,590+k),(460-k,815),(460,815));pen.curveTo((460+k,815),(685,590+k),(685,590));pen.closePath()
        polygon([(650,370),(710,430),(1030,110),(970,50)]);advance=1100
    else:
        rect(110,610,880,180);circle(200,700,90);circle(990,700,90)
        rect(110,190,880,65);rect(110,405,880,65);circle(110,330,140);circle(990,330,140)
        # Dark holes use opposite winding.
        for x,y,r in [(230,700,55),(860,330,60)]:
            k=.55228475*r;pen.moveTo((x+r,y));pen.curveTo((x+r,y-k),(x+k,y-r),(x,y-r));pen.curveTo((x-k,y-r),(x-r,y-k),(x-r,y));pen.curveTo((x-r,y+k),(x-k,y+r),(x,y+r));pen.curveTo((x+k,y+r),(x+r,y+k),(x+r,y));pen.closePath()
        advance=1130
    name=f'uni{code:04X}';glyphs[name]=rawpen.glyph();metrics[name]=(advance,0)
fb.setupCharacterMap({code:f'uni{code:04X}' for code in art})
fb.setupGlyf(glyphs);fb.setupHorizontalMetrics(metrics);fb.setupHorizontalHeader(ascent=950,descent=-50)
fb.setupNameTable({'familyName':'Mac Desktop Symbols','styleName':'Regular','uniqueFontIdentifier':'MacDesktopSymbols-Regular-1','fullName':'Mac Desktop Symbols','psName':'MacDesktopSymbols-Regular'})
fb.setupOS2(sTypoAscender=950,sTypoDescender=-50,usWinAscent=950,usWinDescent=50);fb.setupPost();fb.setupMaxp()
output=root/'home/.local/share/fonts/MacDesktopSymbols.ttf';output.parent.mkdir(parents=True,exist_ok=True);fb.save(output)
print(output)
