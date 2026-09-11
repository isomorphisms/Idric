# ncurses boundary map

Status: requirements and source inventory only. All Idriç hooks are unimplemented
in this change. Python names in the observed column are not assumed to be
exported C symbols. The C column names adapter candidates, not a mechanically
verified CPython-to-C call graph.

## Source pin

All VisiData files below refer to commit
`1d8a6fcd7f031a140c5662943af868e9108343ed` in `saulpw/visidata`:

- [mainloop.py](https://github.com/saulpw/visidata/blob/1d8a6fcd7f031a140c5662943af868e9108343ed/visidata/mainloop.py)
- [vdobj.py](https://github.com/saulpw/visidata/blob/1d8a6fcd7f031a140c5662943af868e9108343ed/visidata/vdobj.py)
- [tuiwin.py](https://github.com/saulpw/visidata/blob/1d8a6fcd7f031a140c5662943af868e9108343ed/visidata/tuiwin.py)
- [mouse.py](https://github.com/saulpw/visidata/blob/1d8a6fcd7f031a140c5662943af868e9108343ed/visidata/mouse.py)
- [color.py](https://github.com/saulpw/visidata/blob/1d8a6fcd7f031a140c5662943af868e9108343ed/visidata/color.py)
- [editor.py](https://github.com/saulpw/visidata/blob/1d8a6fcd7f031a140c5662943af868e9108343ed/visidata/editor.py)

## Observed families and proposed semantic hooks

| Family | Observed Python surface and file | Candidate C boundary | Public semantic hook |
| --- | --- | --- | --- |
| Start and finish | use_env, initscr, endwin; mainloop | use_env, newterm or initscr, endwin, delscreen | open/close terminal with ownership and acquisition/cleanup outcomes |
| Input mode | noecho, raw, window.keypad; mainloop | noecho, raw/cbreak and counterparts, keypad | configure explicit input policy |
| Save and resume modes | def_prog_mode, reset_prog_mode; mainloop/vdobj/editor | def_prog_mode, reset_prog_mode | suspend/resume terminal |
| Cursor visibility | curs_set; mainloop | curs_set | request cursor visibility with unsupported result |
| Wait and flush | window.timeout, flushinp; mainloop/vdobj | wtimeout, flushinp | set input wait; deliberately discard pending input |
| Wide and legacy input | window.get_wch, getch, keyname; vdobj | wget_wch, wgetch, keyname | read typed event; copy diagnostic key name |
| Geometry | getmaxyx, getparyx; mainloop/vdobj/tuiwin | target-header accessors for window geometry | inspect extent; convert named coordinate spaces |
| Derived window | derwin; tuiwin | derwin; explicit delwin for adapter ownership | borrow child window within parent |
| Clear and background | erase, bkgd; mainloop | werase, wbkgd or wide-background equivalent | erase logical window; set background |
| Present | refresh; mainloop/vdobj; doupdate in editor | wrefresh or staged wnoutrefresh plus doupdate | stage window; present frame |
| Palette | start_color, use_default_colors, init_pair, color_pair; mainloop/color | start_color, use_default_colors, init_pair, COLOR_PAIR/accessors | resolve style against negotiated palette |
| Palette/attributes discovery | COLORS, COLOR_PAIRS, COLOR_* and dynamic A_*; color | target-compiled constants/accessors | inspect capabilities; validate style requests |
| Mouse | mousemask, mouseinterval, getmouse, BUTTON_*, REPORT_MOUSE_POSITION; mouse | mousemask, mouseinterval, getmouse with target MEVENT decoding | request mouse events; receive typed mouse event |
| External editor suspension | endwin, reset_prog_mode, refresh, doupdate; editor | lifecycle and presentation operations above | lend terminal to external action and resume |

`newterm` is a proposed acquisition path, not the observed VisiData call. Unlike
ncurses initscr's exit-on-failure behavior, it permits an adapter to handle a
null failure result and explicit terminal streams. `endwin` and `delscreen`
are separate operations; suspension must not free the screen [N1].

## Required coverage still to finish

Text and line drawing, input-editor cursor movement, clipping, and resize
handling require an additional call-site sweep through the sheet renderer,
cliptext, input editor, menu, canvas, and feature modules. The six inspected
files are NOT an exhaustive curses audit. Candidate operations for that sweep
include `wmove`, wide text/character output, bounded line drawing, attribute
application, `KEY_RESIZE`, and the supported resize entry points. Trace each
actual use before declaring the VisiData lower boundary complete.

Optional families include independent windows, pads, terminal capability queries,
input pushback, panels, forms, and menus. Classify them as required-by-consumer,
general-purpose optional, or intentionally unsupported; do not bulk-import the
whole library to make an inventory appear complete.

## Native boundary obligations

WINDOW and SCREEN remain opaque. Do not copy their layouts into Idriç. Decode
MEVENT through target-verified accessors or an exact target ABI description.
The same caution applies to wint_t, wchar_t, attr_t, chtype, mmask_t, C Boolean
representations, and pointers. A host's sizes or constants are not evidence for
ARMv7, AArch64, or another target.

Some curses operations/constants are macros or lvalue accessors rather than
ordinary callable symbols. The binding inventory must classify each against
the actual target headers; `getmaxyx` and `COLOR_PAIR` cannot simply be treated
as Python-named foreign functions. A tiny target-compiled accessor is a possible
mechanism below this contract, not a requirement to restore the RefC backend.

A selected wide-output API must document how Text is encoded, how its length
argument is measured, which storage is borrowed, and which writes can be
partial. Byte counts, character counts, and screen-cell counts are distinct.
No implicit conversion from Text length to any of those is accepted.

Input decoding must inspect both wget_wch's status and output. Preserve the
ambiguity of an unclassified ERR; never fabricate timeout or EOF [N2]. Enabling
mouse must expose the accepted mask. Borrowed C strings must be copied before
their lifetime ends. Raw status integers and attribute masks stay private.

## Acceptance stages

1. Inventory: every required hook has source provenance, semantics, C mechanism,
   capability conditions, and an explicit implementation status.
2. Header/ABI checks: exact target types, symbols/macros, constants, and link
   dependencies are established. A C probe proves only this stage.
3. Native call path: an executable produced by the named native Idriç backend
   invokes the adapter; no interpreter, RefC, or handwritten substitute counts.
4. Behavior: the positive and negative cases in ../acceptance.tsv execute on
   that artifact, including restoration after failure.
5. Device: phone and tablet physical-terminal behavior is recorded separately.

No stage above has been passed by this documentation-only change. A future
receipt names source, compiler/backend, adapter, library/header version, target,
terminal description, locale, executable hash, and the stage demonstrated.

## Primary foreign-API references

- [N1: lifecycle](https://invisible-island.net/ncurses/man/curs_initscr.3x.html)
- [N2: wide input](https://invisible-island.net/ncurses/man/curs_get_wch.3x.html)
- [N3: presentation](https://invisible-island.net/ncurses/man/curs_refresh.3x.html)
- [ncurses manual index](https://invisible-island.net/ncurses/man/ncurses.3x.html)

Consulted 2026-09-11; these manual pages are not a pinned binary or target ABI.
