# Gameplay video sources

`echo-gameplay-grok-source.mp4` is a 25-second excerpt (00:55–01:20) of the owner's physical-device recording `IMG_7588.MP4`, supplied for ECHO's earlier review. It shows actual gameplay from that recording, not proof of build 25.

The source contains a personal notification above the arena. This excerpt therefore retains only the arena rectangle (384×544, origin 0,164) and removes all audio before sharing with Grok. The five-frame contact sheet was visually checked. The original recording remains untouched and outside Git. No personal notification is included in the derivative.

The owner explicitly asked to send a gameplay recording to Grok to create a creative clip. Any generated cinematic teaser must be presented separately from the authentic App Store gameplay preview; invented game UI or unsupported mechanics must not be represented as gameplay.

Grok produced `echo-grok-cinematic.mp4`, 720×1280, H.264, 30 fps, 9.5 seconds, silent. The downloaded file was inspected through a five-frame contact sheet. `echo-teaser-en.mp4` and `echo-teaser-ru.mp4` add native editorial title cards over the reserved lower area. The cinematic output is labeled as an artistic teaser on the Site. The raw gameplay excerpt is presented separately. No paid upgrade was purchased. Conversation and provenance: `GROK_PROVENANCE.json`.

`previews/echo-app-preview-{en,ru}.mp4` are 25-second App Store preview candidates using the real arena excerpt, native editorial captions, 886×1920 H.264 at 30 fps and an AAC silent track required by Apple’s asset specification. The cinematic Grok clip is not used for these previews. Apple processed both videos successfully on 2026-10-29; placements are saved in the editable 1.1.0 draft, not publicly released.

Editable typography layouts and overlay PNGs are in `layout/`; render those JSON files with `swift scripts/render_marketing.swift <layout.json>`.

Artistic teaser attribution: **Created with Grok**. Commercial-use and attribution sources were reviewed separately in [the bilingual editorial and rights audit](../../lore/EDITORIAL_RIGHTS_AUDIT_2026-10-29.md). No provider endorsement is claimed.
