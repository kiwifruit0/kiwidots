#!/usr/bin/env python3
"""Original procedural pixel landscapes. Rebuild bundled PNGs without dependencies."""
import json
import math
from pathlib import Path
import random
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1] / 'config/.config/desktop-theme'
W, H, SCALE = 480, 300, 8


def rgb(color):
    return tuple(int(color[i:i+2],16) for i in (1,3,5))


def blend(a,b,t):
    return tuple(round(x*(1-t)+y*t) for x,y in zip(a,b))


def landscape(p):
    c={k:rgb(v) for k,v in p['colors'].items()}
    rng=random.Random(37)
    pixels=[[blend(c['bg'],c['secondary'],.025 + .065*y/H) for _ in range(W)] for y in range(H)]
    def rect(x,y,w,h,color):
        left, right = max(0,x), min(W,x+w)
        if right <= left:
            return
        for yy in range(max(0,y),min(H,y+h)):
            pixels[yy][left:right]=[color]*(right-left)
    # Sparse stars and an off-centre stepped moon leave a quiet central workspace.
    for _ in range(100):
        x,y=rng.randrange(W),rng.randrange(12,130)
        rect(x,y,1,1,blend(c['bg'],c['fg'],rng.uniform(.2,.55)))
    mx,my,r=365,66,21
    for y in range(my-r,my+r+1):
        width=int(math.sqrt(max(0,r*r-(y-my)**2)))
        rect(mx-width,y,width*2+1,1,blend(c['fg'],c['accent'],.25))
    # Quantised, layered terrain and a narrow reflective lake.
    for layer,(base,amp,color) in enumerate([(151,25,blend(c['bg'],c['accent'],.18)),(181,29,blend(c['bg'],c['secondary'],.15)),(224,20,c['surface'])]):
        for x in range(W):
            y=round((base+math.sin(x/49+layer*2)*amp+math.sin(x/21+layer)*amp*.32)/2)*2
            rect(x,y,1,H-y,color)
    lake=blend(c['bg'],c['cyan'],.075)
    for y in range(235,H):
        half=int(10+(y-235)*1.9)
        rect(300-half,y,half*2,1,lake)
        if y%5==0:
            half=int(4+(y-235)*.2)
            rect(300-half+rng.randrange(-4,5),y,half*2,1,blend(lake,c['secondary'],.2))
    # Procedural conifers frame the scene; the selected palette governs every pixel.
    for layer in (0,1):
        for x in range(-12,W+15,rng.randrange(14,19)):
            if 245<x<380:
                continue
            y=H-18 if layer else 240+rng.randrange(-6,12)
            height=rng.randrange(26,67) if layer else rng.randrange(16,35)
            color=blend(c['bg'],(0,0,0),.28 if layer else .1)
            rect(x,y-height//3,2,height//3+4,color)
            for yy in range(height):
                width=int(yy/height*height*.25)
                if yy%9<2:
                    width=max(0,width-3)
                rect(x-width,y-height+yy,width*2+1,1,color)
    return pixels


def png(path,pixels):
    def chunk(kind,data):
        return struct.pack('!I',len(data))+kind+data+struct.pack('!I',zlib.crc32(kind+data))
    raw=bytearray()
    for row in pixels:
        line=b'\0'+b''.join(bytes(color)*SCALE for color in row)
        raw.extend(line*SCALE)
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',W*SCALE,H*SCALE,8,2,0,0,0))+
                     chunk(b'tEXt',b'Source\0Original procedural artwork; scripts/generate-theme-wallpapers.py')+
                     chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))


if __name__=='__main__':
    for path in (ROOT/'palettes').glob('*.json'):
        png(ROOT/'wallpapers'/(path.stem+'.png'),landscape(json.loads(path.read_text())))
