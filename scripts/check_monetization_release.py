#!/usr/bin/env python3
"""Check a built app before a monetization release. No cabinet writes."""
import argparse
import json
import plistlib
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('app', type=Path, help='Built Echo.app directory')
parser.add_argument('--live', action='store_true', help='Require owner-configured live release inputs')
args = parser.parse_args()
info = plistlib.loads((args.app / 'Info.plist').read_bytes())
errors = []
watch = args.app / 'Watch'
if any('GoogleMobileAds' in str(p) or 'UserMessagingPlatform' in str(p) for p in watch.rglob('*')):
    errors.append('Advertising SDK was embedded in Watch')
for plist in watch.rglob('Info.plist'):
    data = plistlib.loads(plist.read_bytes())
    if any(k.startswith('GAD') or k.startswith('EchoReleasePolicy') for k in data):
        errors.append('Advertising configuration was embedded in Watch')
if info.get('CFBundleIdentifier') != 'com.sergiiziborov.Echo':
    errors.append('Unexpected app identity')
if info.get('EchoAdSDKIncluded') is True and info.get('GADDelayAppMeasurementInit') is not True:
    errors.append('Measurement initialization is not delayed')
if args.live:
    if info.get("EchoAdSDKIncluded") is not True:
        errors.append("Advertising SDK is not compiled into this binary")
    app_id = info.get('GADApplicationIdentifier', '')
    unit_id = info.get('EchoInterstitialUnitID', '')
    if not app_id.startswith('ca-app-pub-') or '~' not in app_id or '3940256099942544' in app_id:
        errors.append('Real AdMob App ID missing or test ID present')
    if not unit_id.startswith('ca-app-pub-') or '/' not in unit_id or '3940256099942544' in unit_id:
        errors.append('Real interstitial unit missing or test ID present')
    if not info.get('EchoReleasePolicyURL', '').startswith('https://'):
        errors.append('Production HTTPS policy endpoint missing')
    import base64
    try:
        if len(base64.b64decode(info.get('EchoReleasePolicyPublicKey', ''), validate=True)) != 32:
            errors.append('Production Ed25519 public key missing')
    except ValueError:
        errors.append('Invalid policy public key')
print(json.dumps({'result': 'FAIL' if errors else 'PASS', 'live': args.live, 'errors': errors}, indent=2))
raise SystemExit(1 if errors else 0)
