#!/usr/bin/env python3
"""Compose editable localized captions around native ECHO screenshots.
No artificial game UI is generated. Render the JSON with render_marketing.swift.
"""
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
CAP = ROOT / 'docs/app-store/captures-1.1.0'
OUT = ROOT / 'docs/app-store/marketing-1.1.0'
COPY = {
 'ru': [
  ('Твой маршрут\nстановится эхом.', 'Собери искры. Найди выход. Прошлое уже идёт по твоему следу.'),
  ('11 регионов.\nОдна Дорога.', '77 карт через повреждённые станции. Унеси к Маяку новую запись.'),
  ('Целый мир\nна запястье.', '36 комнат на Apple Watch. Поверни колёсико — исправь маршрут.'),
  ('iPhone — экран.\nЧасы — пульт.', 'Запусти ECHO на iPhone и выбери пульт на часах.'),
  ('Собирай смысл\nпо крупицам.', 'Эпиктет, Камю и научные заметки. Архив открывается по мере пути.'),
  ('Знание остаётся\nс тобой.', 'Настраивай инструменты Сигнала. Исследования переживают попытку.'),
  ('Подготовься\nк новому пути.', 'Выбери способности. Следующий маршрут построишь сам.'),
  ('Дальше —\nнеизвестность.', 'Ежедневный маршрут и процедурные глубины. Продолжай открывать новое.'),
 ],
 'en': [
  ('Your route becomes\nyour echo.', 'Collect the sparks. Find the exit. Your past is already following.'),
  ('11 regions.\nOne Fold Road.', '77 maps through damaged stations. Bring a new record to the Lighthouse.'),
  ('A whole world\non your wrist.', '36 rooms on Apple Watch. Turn the Crown back to change your route.'),
  ('iPhone is the screen.\nWatch is the controller.', 'Launch ECHO on iPhone and choose the remote on your Watch.'),
  ('Find meaning,\nfragment by fragment.', 'Epictetus, Camus and science notes. Recover the Archive as you play.'),
  ('Keep what\nyou have learned.', 'Calibrate the Signal’s tools. Your research survives each attempt.'),
  ('Prepare for\na different route.', 'Choose your abilities. The next turn is yours to make.'),
  ('Beyond lies\nthe unknown.', 'Daily routes and procedural depths. Keep discovering something new.'),
 ]}

def image(path, x, y, w, h, radius=0):
 return dict(image=str(path.relative_to(ROOT)), x=x,y=y,w=w,h=h,radius=radius)
def text(value,x,y,w,h,size,color='F1F5FA',bold=False):
 return dict(text=value,x=x,y=y,w=w,h=h,size=size,color=color,bold=bold)
def fitted(path,x,y,w,h,radius=24):
 iw,ih=Image.open(path).size;scale=min(w/iw,h/ih);dw,dh=iw*scale,ih*scale
 return image(path,x+(w-dw)/2,y+(h-dh)/2,dw,dh,radius)
def sources(lang,device):
 native=CAP/lang/device
 old=ROOT/'docs/app-store'/('ru' if lang=='ru' else '')
 gameplay=old/('ipad/01-gameplay.jpg' if device=='ipad' else 'iphone/play/01-gameplay.jpg')
 deep=old/('ipad/03-deep-time.jpg' if device=='ipad' else 'iphone/play/04-deep-time.jpg')
 return [gameplay,native/'atlas.png',CAP/'watch'/lang/'01-wrist-run.png',CAP/lang/'remote-phone.png',native/'archive.png',native/'research.png',native/'loadout.png',deep]

def main():
 pages=[];provenance=[]
 for lang in ['en','ru']:
  for device,width,height in [('phone69',1320,2868),('phone65',1284,2778),('ipad',2064,2752)]:
   sx=width/1320;sy=height/2868;fs=min(sx,sy)
   for number,(path,(title,body)) in enumerate(zip(sources(lang,device),COPY[lang]),1):
    if not path.exists(): raise SystemExit('Missing native source: '+str(path))
    items=[dict(x=0,y=0,w=width,h=12,fill='64E2F5'),text('E C H O',100*sx,65*sy,width-200*sx,90*sy,45*fs,'64E2F5',True),text(title,100*sx,190*sy,width-200*sx,270*sy,91*fs,bold=True),text(body,100*sx,465*sy,width-200*sx,170*sy,40*fs,'B2C3D9')]
    area=(90*sx,680*sy,width-180*sx,height-830*sy)
    if number==3:
     items.append(fitted(path,140*sx,760*sy,width-280*sx,1420*sy,70*sx))
     hint=('Играй на часах\nКолёсико — откат · касание — маршрут' if lang=='ru' else 'Play on your Watch\nCrown to rewind · touch to steer')
     items.append(text(hint,100*sx,2300*sy,width-200*sx,290*sy,47*fs,'EDC675',True))
    elif number==4:
     items.append(fitted(path,*area))
     watch=CAP/'watch'/lang/'05-remote.png'
     items.append(fitted(watch,width*.48,height*.65,width*.46,height*.28,45*sx))
    else: items.append(fitted(path,*area))
    items.append(text(f'{number:02} / 08   ·   '+('ПАМЯТЬ · ВЫБОР · ПОСЛЕДСТВИЯ' if lang=='ru' else 'MEMORY · CHOICE · CONSEQUENCES'),100*sx,height-95*sy,width-200*sx,60*sy,26*fs,'8199B9'))
    output=OUT/lang/device/f'{number:02}.png'
    pages.append(dict(width=width,height=height,background='061020',output=str(output.relative_to(ROOT)),items=items))
    provenance.append(dict(output=str(output.relative_to(ROOT)),source=str(path.relative_to(ROOT)),native_capture=('Build 27 native menu fixture' if number in (6,7) else 'Build 27 native menu fixture' if number in (2,5) else 'Earlier unchanged gameplay or native Watch/setup capture; see capture README'),caption=COPY[lang][number-1]))
 for lang in ['en','ru']:
  for device,width,height in [('duo-outer',1398,2034),('duo-inner',2007,2853)]:
   fs=height/2868
   for name,index in [('research',5),('loadout',6)]:
    title,body=COPY[lang][index];source=CAP/lang/device/(name+'.png')
    output=OUT/lang/'duo'/(device+'-'+name+'.png')
    items=[dict(x=0,y=0,w=width,h=12,fill='64E2F5'),text('E C H O',80,55,width-160,90,40*fs,'64E2F5',True),text(title,80,160*fs,width-160,270*fs,91*fs,bold=True),text(body,80,440*fs,width-160,170*fs,40*fs,'B2C3D9'),fitted(source,80,640*fs,width-160,height-740*fs,28)]
    pages.append(dict(width=width,height=height,background='061020',output=str(output.relative_to(ROOT)),items=items))
    provenance.append(dict(output=str(output.relative_to(ROOT)),source=str(source.relative_to(ROOT)),native_capture='Native width fixture; not a physical Duo purchase or hardware test',caption=COPY[lang][index]))
 OUT.mkdir(parents=True,exist_ok=True)
 (OUT/'layouts.json').write_text(json.dumps(pages,ensure_ascii=False,indent=2)+'\n')
 (OUT/'provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n')
 print('Prepared',len(pages),'captioned native screenshots')
if __name__=='__main__':main()
