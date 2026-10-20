# Dock animation credits

The five animations in this directory are original work authored for CollegeOS
by its own generator script (Lottie 5.7 format, 36 × 36 artboard, 60 fps,
90 frames). They embed no third-party animation, font, image or licence, so the
simplest way to describe their terms is that they ship under the same terms as
the application itself. Nothing here is downloaded at runtime and no network
path touches them.

| Destination | File | What it draws |
| --- | --- | --- |
| Home | `home.json` | A roof and house body draw on, then four window and door panels fill the facade |
| Attendance | `tasks.json` | The clipboard outline draws, then three rows land one after another, each with its own tick |
| Timetable | `calendar.json` | The frame draws on, the two rings drop in, the header rules across and the marked day pops in last |
| Tasks | `completed.json` | A ring draws in, the tick strokes through it and a burst of rays settles |
| Notes | `library.json` | Both pages of an open book swing out, then six ruled lines draw across them |

Every file is built from the same primitives, which is what lets the dock treat
them as one family:

- a cyan → cobalt → violet gradient (`#42C8FF`, `#647BFF`, `#A65CFF`) painted
  through gradient strokes and, for the two filled layers, a gradient fill. The
  dock itself paints each animation in a single accent through a `srcIn` filter,
  so the gradient exists only in the source artwork;
- a soft glow stroke painted at 28 % opacity and roughly twice each line's own
  width, behind every outline, ring, panel and marked day. The halo is part of
  the family's weight — a glyph drawn without it reads visibly lighter than its
  siblings — and it is flattened to the same single accent along with the rest;
- one 36 × 36 artboard, with the subject held between roughly 26 and 36 px, so
  the one `glyphScale` value measured per destination is enough to give all five
  the same visual weight in the dock's 24 px slot;
- a blank first frame and a fully drawn final frame — every stroke trims and
  fades itself in — which is why the dock rests unselected destinations on the
  finished frame instead of the opening one;
- a shared `Settle Controller` null layer that lifts and settles the whole glyph
  by about 4.5 % once the drawing completes.

The artwork is edited in exactly one place: the generator that produced it.
Re-exporting a file by hand would drift from its siblings.

## Previous set

The earlier dock animations — LottieFiles works by Ision Industries, Ayodeji,
sabbir ahmed, kamran Ali and Levy Cristian, with their provenance and the Lottie
Simple License notice recorded in this file before this change — are no longer
bundled. They were archived in `tmp/lottie_previous/` in the working tree. That
licence covered distribution inside the application; it did not cover
redistributing the animations as standalone files, so the archive must not be
published as an animation pack.
