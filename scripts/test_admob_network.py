#!/usr/bin/env python3
"""Opt-in native UMP/test-ad smoke; never uses a physical device or live ad unit."""
import argparse
import os
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument('--simulator', required=True, help='UUID of an isolated test simulator')
parser.add_argument('--result', required=True, type=Path)
parser.add_argument('--derived-data', required=True, type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
scheme = root / 'Echo.xcodeproj/xcshareddata/xcschemes/EchoAdNetworkSmoke.xcscheme'
environment = {**os.environ, 'DEVELOPER_DIR': '/Applications/Xcode.app/Contents/Developer'}

def run(command):
    subprocess.run(command, cwd=root, env=environment, check=True)

try:
    run(['xcodegen', 'generate', '--spec', 'project-admob.yml'])
    tree = ET.parse(root / 'Echo.xcodeproj/xcshareddata/xcschemes/Echo.xcscheme')
    action = tree.getroot().find('TestAction')
    assert action is not None
    action.set('shouldUseLaunchSchemeArgsEnv', 'NO')
    variables = ET.SubElement(action, 'EnvironmentVariables')
    ET.SubElement(variables, 'EnvironmentVariable', key='ECHO_RUN_AD_NETWORK_TESTS',
                  value='1', isEnabled='YES')
    tree.write(scheme, encoding='UTF-8', xml_declaration=True)
    run(['xcodebuild', 'test', '-project', 'Echo.xcodeproj', '-scheme', 'EchoAdNetworkSmoke',
         '-configuration', 'Debug', '-destination', f'platform=iOS Simulator,id={args.simulator}',
         '-derivedDataPath', str(args.derived_data), '-resultBundlePath', str(args.result),
         '-only-testing:EchoTests/AdMobNetworkTests', '-parallel-testing-enabled', 'NO',
         '-collect-test-diagnostics', 'never', '-test-timeouts-enabled', 'YES',
         '-default-test-execution-time-allowance', '45',
         '-maximum-test-execution-time-allowance', '60', 'CODE_SIGNING_ALLOWED=NO'])
finally:
    scheme.unlink(missing_ok=True)
    run(['xcodegen', 'generate', '--spec', 'project.yml'])
