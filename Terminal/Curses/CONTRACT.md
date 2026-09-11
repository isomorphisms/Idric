# Typed terminal operations

Design notation only. Parameterized type families, ownership restrictions,
and action signatures here have not been elaborated or checked by Idriç.
`Outcome(Success, Failure)` denotes a result choice; it is not a newly installed
prelude type. Parenthesized parameter lists name roles, not curried application.

## 1. Own a session, borrow its windows

```text
Session(session_id, phase)
phase ≝ active | suspended | closing | closed
Window(session_id, window_id, parent_id, geometry_revision)
DrawAuthority(session_id, owner)
```

Opening a session returns either an active session with its capabilities or an
acquisition failure with cleanup information. No usable window exists before
successful acquisition. An independent window is owned by the session; a
derived window additionally borrows its parent. Children must be released
before their parent. The standard screen is borrowed, not independently freed.
Overlapping windows and shared parent storage are real aliases: ownership must
not imply that two derived windows have independent backing cells.

Only the owner holding draw authority may invoke curses, including input and
presentation. Worker tasks may send messages to that owner, not receive curses
window handles. This is a proposed discipline, not a claim that VisiData's
Python threads already enforce it.

```text
open terminal using settings
  {settings: TerminalSettings}
  → Outcome(OpenedSession, AcquisitionFailure)

suspend terminal
  {terminal: Session(s, active), authority: DrawAuthority(s, owner)}
  → Outcome(Session(s, suspended), TransitionFailure)

resume terminal
  {terminal: Session(s, suspended), authority: DrawAuthority(s, owner)}
  → Outcome(ResumedSessionWithFreshGeometry, TransitionFailure)

close terminal
  {terminal: Session(s, phase), all_child_windows_released: ReleaseCertificate}
  → Outcome(Session(s, closed), CleanupFailure)
```

These transitions consume or exclusively borrow authority. Each failure must
return the remaining ownership and a truthful resulting state; failing halfway
through resume does not produce an active session. A cleanup failure reports
which restoration or release failed and retains a legal recovery route. Do not
lose ownership merely by returning an error. `endwin` restores terminal mode;
it does not by itself free the screen's storage. The adapter must distinguish
suspension, restoration, and final release [N1].

Process death and uncatchable termination are outside the guaranteed cleanup
model. Ordinary errors and cooperative cancellation are inside it. Signal
integration must arrange owner-thread handling; this contract does not authorize
calling arbitrary curses operations from an asynchronous signal handler.

## 2. Coordinates carry their space and revision

```text
ScreenPosition(session_id, geometry_revision)
WindowPosition(window_id, geometry_revision)
CellExtent                         -- rows and columns, each positive
ViewportExtent                     -- may be empty
CellSpan(window_id, geometry_revision)
```

A position certifies `0 ≤ row < height` and `0 ≤ column < width` in its named
space. It is not a data-row index, a byte offset, or a plot coordinate. Public
operations use named row/column roles; C's positional conventions stay below
the boundary. Conversions between parent, child, and screen coordinates are
explicit and checked.

Resize creates a new geometry revision. Old positions, clipping certificates,
and application hit regions cannot be reused without revalidation. An empty
viewport means there is nothing to draw; it is not permission to create a
zero-size curses window and accept implementation-dependent expansion.

## 3. Input is an event, not an integer sentinel

```text
InputWait ≝ poll | wait_for(Duration) | wait_forever
TerminalEvent ≝ character(UnicodeScalar)
              | key(SpecialKey)
              | mouse(MouseEvent)
              | resized(GeometryChange)
ReadResult ≝ event(TerminalEvent)
           | no_event(NoEventEvidence)
           | failed(InputFailure)
```

`Duration` in wait_for is positive; poll expresses zero wait. Escape-sequence
disambiguation has its own duration, not an accidental reuse of the input wait.
The adapter translates C's timeout conventions. Unicode NUL is a character,
not no_event. Decoding errors and unknown key codes remain distinguishable.

The wide input interface returns a character or a special-key code according
to its status. `ERR` alone is insufficient evidence for a particular timeout,
EOF, or I/O error. Return no_event only when the adapter has adequate evidence;
otherwise retain an indeterminate input failure. Do not copy Python code's
blanket conversion of curses exceptions into an empty key string [N2, V1].
A narrow-character fallback does not establish wide-input acceptance.

Mouse support is negotiated. Enabling it returns the accepted event set, which
may be smaller than the requested set. Mouse positions belong to screen space;
which sheet cell or menu action they target is an application decision.

## 4. Text, cells, and styles are different objects

```text
TerminalText                       -- validated policy for controls and layout
DisplayWidth(policy, text)          -- measured terminal cells, not bytes
StyleRequest                       -- requested visual meaning
ResolvedStyle(session_id, palette_revision)
ColorRequest ≝ terminal_default | palette_entry(ColorIndex)
```

Unicode scalar count, grapheme boundaries, encoded byte length, and display
width must not be equated. Width/segmentation policy and terminal behavior need
explicit target tests. Handle tabs, newlines, combining marks, control text,
and double-width characters deliberately. Clipping must not split an encoding
or leave half a wide displayed character. The policy for unsupported glyphs or
attributes must be explicit, not an undocumented substitution.

Palette size and color-pair capacity are capabilities, not universal constants.
A default foreground/background is a named alternative, not a negative color
index in domain code. Pair allocation belongs to the adapter; pair reuse
invalidates or re-resolves affected styles and frames. Unknown attributes,
monochrome fallback, and palette exhaustion have explicit outcomes.

```text
write text to window at position with style
  {window: Window(s, w, parent, g), position: WindowPosition(w, g),
   text: TerminalText, style: ResolvedStyle(s, palette_revision),
   authority: DrawAuthority(s, owner)}
  → DrawOutcome
```

Drawing is not automatically transactional. A low-level failure may follow
partial output or cursor movement; the adapter must report possible partial
mutation and require an appropriate redraw rather than promising rollback.

## 5. Compose first, present separately

```text
stage window on terminal
  {window: Window(s, w, parent, g), frame: Frame(s, g, palette_revision)}
  → Outcome(StagedFrame, DrawingFailure)

present frame on terminal
  {frame: StagedFrame(s, g, palette_revision), authority: DrawAuthority(s, owner)}
  → Outcome(PresentationReceipt, PresentationFailure)
```

Logical window-buffer erasure is not an instruction to clear the physical
terminal at every iteration. ncurses separates window/virtual-screen updates
from physical presentation; `wnoutrefresh` and `doupdate` expose that separation
[N3]. Damage, overlap order, and child/parent synchronization need explicit
adapter behavior. A successful library return is not proof of what a physical
device visibly displayed.

The application owns redraw scheduling and command-prefix interpretation.
Idle input may block. The library does not mandate a permanent polling loop.
Resuming after an external editor invalidates assumptions about physical-screen
contents and may also change geometry.

## 6. Dynamic capabilities remain checked boundaries

TerminalSettings names input/output channels, terminal description, locale,
input mode, and requested features. Piped data input is not implicitly the
interactive terminal input channel. Raw input and cbreak input are distinct
policies; neither is selected merely because a Boolean happens to be true.

A capability certificate must come from a validated backend/terminal session,
not from user-provided integers or an unchecked constructor. Missing mouse,
colors, resizing extensions, or wide-character support is an explicit absence.
Pads, panels, menus, and forms are optional future families, not dependencies
for the first VisiData-inspired slice.

## References

- [N1: ncurses session lifecycle](https://invisible-island.net/ncurses/man/curs_initscr.3x.html)
- [N2: ncurses wide input](https://invisible-island.net/ncurses/man/curs_get_wch.3x.html)
- [N3: ncurses presentation](https://invisible-island.net/ncurses/man/curs_refresh.3x.html)
- [V1: inspected VisiData input implementation](https://github.com/saulpw/visidata/blob/1d8a6fcd7f031a140c5662943af868e9108343ed/visidata/vdobj.py)

The ncurses manual links were consulted on 2026-09-11 and are moving upstream
documents. Actual adapter acceptance must additionally pin its concrete library
and headers. V1 is an immutable source reference.
