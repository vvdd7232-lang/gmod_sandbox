#!/bin/bash
# Procedural textures for GMod Sandbox (ImageMagick 6)
# Run from repo root: bash tools/make_textures.sh
set -e
cd "$(dirname "$0")/.."
mkdir -p assets

# ---------------- helpers ----------------
# low-amp gaussian noise blended over an image
noise_over() { # input output amp
    convert "$1" \( +clone -attenuate "$3" +noise Gaussian \) \
        -compose blend -define compose:args="$3,100" -composite "$2"
}

# ---------------- grid_floor (1024) ----------------
S=1024
convert -size ${S}x${S} gradient:'#2b2f33'-'#33373c' \
    \( -size ${S}x${S} radial-gradient:'#3d4349'-'#262a2e' \) \
    -compose blend -define compose:args=35,100 -composite /tmp/f0.png
noise_over /tmp/f0.png /tmp/f1.png 6

# build a line layer
convert -size ${S}x${S} xc:none -alpha set \
    -stroke 'rgba(0,0,0,0.55)' -strokewidth 6 -draw "line 0,256 1023,256" \
    -stroke 'rgba(0,0,0,0.55)' -strokewidth 6 -draw "line 0,512 1023,512" \
    -stroke 'rgba(0,0,0,0.55)' -strokewidth 6 -draw "line 0,768 1023,768" \
    -stroke 'rgba(0,0,0,0.4)'  -strokewidth 4 -draw "line 256,0 256,1023" \
    -stroke 'rgba(0,0,0,0.4)'  -strokewidth 4 -draw "line 512,0 512,1023" \
    -stroke 'rgba(0,0,0,0.4)'  -strokewidth 4 -draw "line 768,0 768,1023" \
    -stroke 'rgba(150,170,185,0.30)' -strokewidth 1 \
    -draw "line 0,255 1023,255" -draw "line 0,511 1023,511" -draw "line 0,767 1023,767" \
    -draw "line 255,0 255,1023" -draw "line 511,0 511,1023" -draw "line 767,0 767,1023" \
    /tmp/ln.png
# fine 1/8 grid, very faint
convert -size ${S}x${S} xc:none -alpha set \
    -stroke 'rgba(0,0,0,0.22)' -strokewidth 1 \
    -draw "line 0,128 1023,128" -draw "line 0,384 1023,384" -draw "line 0,640 1023,640" -draw "line 0,896 1023,896" \
    -draw "line 128,0 128,1023" -draw "line 384,0 384,1023" -draw "line 640,0 640,1023" -draw "line 896,0 896,1023" \
    -stroke 'rgba(150,170,185,0.10)' -strokewidth 1 \
    -draw "line 0,127 1023,127" -draw "line 0,383 1023,383" -draw "line 0,639 1023,639" -draw "line 0,895 1023,895" \
    -draw "line 127,0 127,1023" -draw "line 383,0 383,1023" -draw "line 639,0 639,1023" -draw "line 895,0 895,1023" \
    /tmp/ln2.png
# grunge patches
convert /tmp/ln.png /tmp/ln2.png -compose over -composite /tmp/ln3.png
convert /tmp/f1.png /tmp/ln3.png -compose over -composite assets/grid_floor.jpg
# subtle edge darkening vignette handled in material; done

# ---------------- grid_wall (1024) ----------------
convert -size ${S}x${S} gradient:'#4e545b'-'#3a3f45' \
    \( -size ${S}x${S} radial-gradient:'#5a6169'-'#353a3f' \) \
    -compose blend -define compose:args=45,100 -composite /tmp/w0.png
noise_over /tmp/w0.png /tmp/w1.png 4
# seams every 256 (panel ~1.25m)
for y in 256 512 768; do
    convert /tmp/w1.png -fill 'rgba(20,22,25,0.9)' -draw "rectangle 0,$((y-2)) 1023,$((y+2))" \
        -fill 'rgba(160,170,180,0.25)' -draw "rectangle 0,$((y+3)) 1023,$((y+3))" /tmp/w1.png
done
for x in 256 512 768; do
    convert /tmp/w1.png -fill 'rgba(20,22,25,0.75)' -draw "rectangle $((x-2)),0 $((x+2)),1023" \
        -fill 'rgba(160,170,180,0.22)' -draw "rectangle $((x+3)),0 $((x+3)),1023" /tmp/w1.png
done
# vertical subtle streaks (concrete form marks)
convert -size ${S}x${S} xc:none -alpha set +noise Gaussian -attenuate 0.55 -negate \
    -channel A -evaluate multiply 0.06 +channel -motion-blur 0x40+90 \
    -fill none -stroke 'rgba(255,255,255,0.5)' -draw "line 0,500 1023,500" /tmp/streak.png
convert /tmp/w1.png /tmp/streak.png -compose screen -composite /tmp/w2.png
# bolts at panel corners
for x in 128 384 640 896; do
  for y in 128 384 640 896; do
    convert /tmp/w2.png -fill 'rgba(10,10,12,0.9)' -draw "circle $x,$y $((x+5)),$y" \
        -fill 'rgba(190,200,210,0.5)' -draw "circle $((x+1)),$((y-1)) $((x+4)),$((y-1))" /tmp/w2.png
  done
done
convert /tmp/w2.png assets/grid_wall.jpg

# ---------------- wood (512) ----------------
Q=512
convert -size ${Q}x${Q} gradient:'#a5723c'-'#7c5528' \
    \( -size ${Q}x${Q} xc:white -attenuate 0.8 +noise Gaussian \) -compose blend -define compose:args=8,100 -composite \
    -motion-blur 0x60+0 /tmp/wd.png
for x in 0 85 171 256 341 427; do
    convert /tmp/wd.png -fill 'rgba(30,18,6,0.85)' -draw "rectangle $x,0 $((x+3)),511" /tmp/wd.png
    convert /tmp/wd.png -fill 'rgba(255,220,160,0.12)' -draw "rectangle $((x+4)),0 $((x+4)),511" /tmp/wd.png
done
# darker border frame
convert /tmp/wd.png -fill 'rgba(15,9,3,0.6)' -draw "rectangle 0,0 511,14" -draw "rectangle 0,497 511,511" \
    -draw "rectangle 0,0 14,511" -draw "rectangle 497,0 511,511" /tmp/wd.png
# nail dots
for ((i=0;i<14;i++)); do
  x=$(( (RANDOM % 430) + 40 )); y=$(( (RANDOM % 460) + 25 ));
  convert /tmp/wd.png -fill 'rgba(25,15,5,0.9)' -draw "circle $x,$y $((x+4)),$y" /tmp/wd.png
done
noise_over /tmp/wd.png assets/wood_crate.png 3

# ---------------- steel plate (512) ----------------
convert -size ${Q}x${Q} gradient:'#5d6268'-'#474b50' \
    \( -size ${Q}x${Q} xc:white -attenuate 0.7 +noise Gaussian \) -compose blend -define compose:args=10,100 -composite \
    -motion-blur 0x30+0 /tmp/st.png
# brushed vertical on top of horizontal
convert /tmp/st.png \( -size ${Q}x${Q} xc:white -attenuate 0.5 +noise Gaussian \) \
    -compose blend -define compose:args=5,100 -composite -motion-blur 0x20+90 /tmp/st.png
# plate seams every 256 with rivets
convert /tmp/st.png -fill 'rgba(15,16,18,0.9)' -draw "rectangle 0,254 511,258" \
    -draw "rectangle 254,0 258,511" /tmp/st.png
convert /tmp/st.png -fill 'rgba(230,235,240,0.18)' -draw "rectangle 0,259 511,259" \
    -draw "rectangle 259,0 259,511" /tmp/st.png
for cx in 48 464; do for cy in 48 464; do
  convert /tmp/st.png -fill 'rgba(10,10,12,0.95)' -draw "circle $cx,$cy $((cx+6)),$cy" \
      -fill 'rgba(200,205,210,0.35)' -draw "circle $((cx+1)),$((cy-1)) $((cx+5)),$((cy-1))" /tmp/st.png
done; done
noise_over /tmp/st.png assets/metal_plate.png 3

# ---------------- barrel steel (512) ----------------
convert -size ${Q}x${Q} gradient:'#6f88a6'-'#4c5f79' \
    \( -size ${Q}x${Q} xc:white -attenuate 0.8 +noise Gaussian \) -compose blend -define compose:args=9,100 -composite \
    -motion-blur 0x25+90 /tmp/b1.png
# horizontal ribs
for y in 64 128 192 256 320 384 448; do
  convert /tmp/b1.png -fill 'rgba(10,16,26,0.55)' -draw "rectangle 0,$y 511,$((y+4))" \
      -fill 'rgba(220,235,250,0.14)' -draw "rectangle 0,$((y-3)) 511,$((y-3))" /tmp/b1.png
done
# top/bottom rims darker
convert /tmp/b1.png -fill 'rgba(8,12,18,0.7)' -draw "rectangle 0,0 511,10" -draw "rectangle 0,502 511,511" /tmp/b1.png
# scratches
for ((i=0;i<26;i++)); do
  x=$((RANDOM % 400 + 50)); y=$((RANDOM % 480 + 20)); l=$((RANDOM % 40 + 20));
  convert /tmp/b1.png -stroke 'rgba(230,240,250,0.10)' -strokewidth 1 -draw "line $x,$y $((x+l)),$((y+RANDOM%6-3))" /tmp/b1.png
done
noise_over /tmp/b1.png assets/barrel_steel.png 4

# ---------------- barrel red + hazard band (512) ----------------
convert -size ${Q}x${Q} gradient:'#c23b32'-'#8f241d' \
    \( -size ${Q}x${Q} xc:white -attenuate 0.8 +noise Gaussian \) -compose blend -define compose:args=9,100 -composite \
    -motion-blur 0x25+90 /tmp/r1.png
for y in 64 128 192 320 384 448; do
  convert /tmp/r1.png -fill 'rgba(20,5,5,0.5)' -draw "rectangle 0,$y 511,$((y+4))" \
      -fill 'rgba(255,200,190,0.12)' -draw "rectangle 0,$((y-3)) 511,$((y-3))" /tmp/r1.png
done
# hazard band rows 225..295
convert /tmp/r1.png -fill '#e7b423' -draw "rectangle 0,225 511,295" /tmp/r1.png
for ((k=-2;k<8;k++)); do
  x0=$((k*80))
  convert /tmp/r1.png -fill 'rgba(20,15,5,0.9)' -draw "polygon $x0,225 $((x0+34)),225 $((x0+78)),295 $((x0+44)),295" /tmp/r1.png
done
convert /tmp/r1.png -fill 'rgba(10,3,3,0.8)' -draw "rectangle 0,220 511,224" -draw "rectangle 0,296 511,300" /tmp/r1.png
noise_over /tmp/r1.png assets/barrel_red.png 4

# ---------------- hazard chevrons (256, for ramp) ----------------
V=256
convert -size ${V}x${V} xc:'#eeb800' /tmp/hz.png
for ((k=-3;k<8;k++)); do
  x0=$((k*64))
  convert /tmp/hz.png -fill '#1a1a1a' -draw "polygon $x0,0 $((x0+26)),0 $((x0+52)),$V $((x0+26)),$V" /tmp/hz.png
done
noise_over /tmp/hz.png assets/hazard_chevron.png 3

# ---------------- concrete plank light (256, decorative trim) ----------------
for f in assets/grid_floor assets/grid_wall assets/wood_crate assets/metal_plate assets/barrel_steel assets/barrel_red assets/hazard_chevron; do convert "$f.png" -quality 88 "$f.jpg" && rm "$f.png"; done
echo done
ls -la assets/*.png

# ---------------- beach ball stripes (512x256 equirect) ----------------
S2=512; H2=256
convert -size ${S2}x${H2} xc:none -alpha set /tmp/bb.png
idx=0
for c in '#e23b2e' '#f4efe2' '#ffd23e' '#f4efe2' '#2f6fd0' '#f4efe2' '#e8861a' '#f4efe2' '#3aa655' '#f4efe2' '#c33aa0' '#f4efe2'; do
  x0=$((idx*S2/12))
  convert /tmp/bb.png -fill "$c" -draw "rectangle $x0,0 $((x0+S2/12-1)),$((H2-1))" /tmp/bb.png
  idx=$((idx+1))
done
convert /tmp/bb.png -attenuate 4 +noise Gaussian \
    -fill 'rgba(255,255,255,0.35)' -draw "ellipse 120,60 90,40 0,360" /tmp/bb.png
convert /tmp/bb.png assets/beach_ball.png
convert assets/beach_ball.png -quality 90 assets/beach_ball.jpg && rm assets/beach_ball.png

# ---------------- cardboard box (512) ----------------
convert -size ${Q}x${Q} gradient:'#c49a5f'-'#9d7040' \
    \( -size ${Q}x${Q} xc:white -attenuate 0.7 +noise Gaussian \) -compose blend -define compose:args=8,100 -composite \
    -motion-blur 0x20+0 /tmp/cb.png
# corrugation
convert /tmp/cb.png \( -size ${Q}x${Q} xc:white -attenuate 0.3 +noise Gaussian \) \
    -compose blend -define compose:args=6,100 -composite -motion-blur 0x6+0 /tmp/cb.png
# tape stripe vertical with edge shading
convert /tmp/cb.png -fill '#d9b98a' -draw "rectangle 232,0 280,511" \
    -fill 'rgba(90,60,25,0.35)' -draw "rectangle 232,0 238,511" \
    -fill 'rgba(90,60,25,0.35)' -draw "rectangle 274,0 280,511" /tmp/cb.png
# wear on corners
convert /tmp/cb.png -fill 'rgba(60,40,15,0.25)' -draw "rectangle 0,0 511,14" -draw "rectangle 0,497 511,511" \
    -draw "rectangle 0,0 14,511" -draw "rectangle 497,0 511,511" /tmp/cb.png
noise_over /tmp/cb.png assets/cardboard.png
convert assets/cardboard.png -quality 90 assets/cardboard.jpg && rm assets/cardboard.png
