#!/usr/bin/env python3
"""Check the built site's real page links, anchors, assets and SEO metadata."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import json

ROOT=Path(__file__).resolve().parent/'dist'

class Page(HTMLParser):
    def __init__(self,path):
        super().__init__();self.path=path;self.ids=set();self.links=[];self.assets=[];self.h1=0;self.lang='';self.canonical='';self.alternates=set();self.description='';self.title=False
        self.feed(path.read_text())
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if a.get('id'):self.ids.add(a['id'])
        if tag=='html':self.lang=a.get('lang')
        if tag=='h1':self.h1+=1
        if tag=='title':self.title=True
        if tag=='a' and a.get('href'):self.links.append(a['href'])
        if tag in ('script','img','source') and a.get('src'):self.assets.append(a['src'])
        if tag=='video' and a.get('poster'):self.assets.append(a['poster'])
        if tag=='link' and a.get('rel')=='stylesheet':self.assets.append(a['href'])
        if tag=='link' and a.get('rel')=='canonical':self.canonical=a.get('href')
        if tag=='link' and a.get('rel')=='alternate':self.alternates.add(a.get('hreflang'))
        if tag=='meta' and a.get('name')=='description':self.description=a.get('content')

pages={p:Page(p) for p in ROOT.rglob('index.html')}
errors=[]
for file,page in pages.items():
    if page.h1!=1 or page.lang not in ('en','ru') or not page.title or not page.description or not page.canonical or not {'en','ru','x-default'}<=page.alternates:
        errors.append(f'{file.relative_to(ROOT)}: missing heading, language or metadata')
    for href in page.links+page.assets:
        u=urlsplit(href)
        if u.scheme or u.netloc:continue
        target=(ROOT/unquote(u.path).lstrip('/')) if u.path.startswith('/') else file.parent/unquote(u.path)
        if not u.path:target=file
        if target.is_dir():target=target/'index.html'
        if not target.exists():errors.append(f'{file.relative_to(ROOT)}: missing {href}')
        elif u.fragment and target in pages and unquote(u.fragment) not in pages[target].ids:errors.append(f'{file.relative_to(ROOT)}: missing anchor {href}')
assert len(pages)==14,f'Expected 14 localized pages; got {len(pages)}'
assert not errors,'\n'.join(errors)
print(f'PASS: {len(pages)} pages; internal links, fragments, assets and bilingual metadata verified.')

for language, path in [("en", ROOT/"index.html"),("ru", ROOT/"ru/index.html")]:
    text=path.read_text()
    assert text.count("<video ")==2, f"{language}: expected separate gameplay and artistic teaser"
    assert f"echo-teaser-{language}.mp4" in text
print("PASS: localized teaser and authentic gameplay remain distinct.")
