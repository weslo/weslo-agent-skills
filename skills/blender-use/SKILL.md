---
name: blender-use
description: Read before driving Blender from an agent session, through the MCP for Blender (`execute_blender_code`, `look`, `get_scene_info`) or headless (`blender -b`). Covers choosing live or headless; launching Blender, checking what is open before touching it, and closing a Blender you launched when done; opening and saving without losing the file's layout; quitting without saving; rebuilding an edit from the committed file instead of patching the open one; checking with numbers before images, including posing against a stand-in prop; previewing a layered pose over a clip; checking that an export changed only what you meant; and screenshots without the MCP. Use it before the first Blender call of a session. How to model, rig, animate and export is in the `blender-*` and `keyframe-coach` skills.
---

# Using Blender from an agent session

How to drive Blender reliably and cheaply. The `blender-*` skills and `keyframe-coach` cover the craft: modeling, rigging, animation and export settings. This skill is the discipline around running Blender itself, and where they disagree about that, this skill wins; the main case is `keyframe-coach`'s advice not to launch Blender yourself. Project specifics, such as which files matter and how the project exports, live in the project's own agent guidance (`AGENTS.md`), which wins over both.

## Live or headless
- **Live, through the MCP for Blender,** when the user wants to watch, or you need `look` to see the result. It drives the user's own Blender, so what is open there is their work.
- **Headless** (`blender -b --factory-startup <file>.blend --python <script>.py`) for reads, batch checks and exports. It never touches the user's session, and never saves unless the script does.
- **Keep the work in script files either way.** The same script runs live (imported from `execute_blender_code`, as `blender-core` shows) and headless, and a re-run costs one call.

## Starting, opening and quitting
1. **Check the connection** with `get_addon_status`. A connection or handshake failure means Blender isn't running, or its MCP server is off.
2. **Blender isn't running:** launch it yourself, in the background so it doesn't take focus. On macOS, `open -g -a Blender`. Recent versions of the MCP for Blender add-on start their server with Blender, on 127.0.0.1:9876, within seconds. If `get_addon_status` still fails after half a minute, ask the user to click **Start MCP Server** in the add-on's preferences.
3. **Blender is running:** check what it has open before changing anything, with `bpy.data.filepath` and `bpy.data.is_dirty`. If the user's file has unsaved changes, ask before opening another file, reverting or quitting.
4. **Open a file** with `bpy.ops.wm.open_mainfile(filepath=..., load_ui=True)` whenever you might save it. With `load_ui=False` the window keeps its current layout, and a later save writes that layout over the file's own. The MCP connection survives the load.
5. **Quit without saving:** revert, then quit on a timer so the call can reply before Blender exits:
   ```python
   import bpy
   if bpy.data.is_dirty:
       bpy.ops.wm.revert_mainfile()
   bpy.app.timers.register(lambda: bpy.ops.wm.quit_blender() and None, first_interval=0.5)
   ```
6. **Leave preferences alone.** Don't turn off the save prompt or change add-ons from a script: preferences can save themselves, and they are the user's.
7. **Close what you opened.** If you launched Blender, quit it as in step 5 once the work is done, rather than leaving it open for later; launch it again the next time work needs it. Leave a Blender the user had open running.

## Rebuild from the committed file
Don't build up an edit by patching the open file call after call.
- **Put the whole edit in one script that can re-run.** It opens the committed `.blend` (restore it with `git checkout -- <file>.blend` first if a save has touched it), removes and recreates everything it owns, such as its actions, then saves. Re-run it after every change.
- **Why:** patches pile up, and an attempt you discarded is still in the file once something saves. The only way back is then the committed file, with every later change redone.
- **Probes stay out of the save.** Stand-in props, measurement empties and preview settings go in a separate script that runs after the build. Revert or quit without saving when done.
- **Hash the `.blend` before and after** a headless run to prove it didn't save. File size proves nothing: re-saving an untouched file in another Blender version changes it. Each save also rewrites the `.blend1` backup beside it.
- **What the script creates:** give a new action a fake user, or a save drops it while nothing uses it. Give a hold or a loop a manual frame range (`use_frame_range`, `frame_start`, `frame_end`), so the exported clip has the length you mean.

## Check with numbers before images
Images are expensive to keep in context and easy to misread. Measure what the user would notice, print it, and look once the numbers are right.
- **What to measure:** contact (how far a fingertip sits from a surface, and whether anything passes through it), travel (how far a hand moves over a loop, next to the limb it should match), and how far each joint bends.
- **Posing against a prop:** place a stand-in of the prop's real size where the engine will put it, for example a cylinder on a hand's attach point along its grip axis, and measure every part that touches it. For a grip, measure how far each finger wraps around the axis and how far its tip sits off the surface. Then curl each joint a degree at a time until the tip is close without passing through.
- **A pose copied from one side doesn't fit the other on its own.** A grip mirrored from the other hand can wrap a different prop badly, so measure the copy against what that hand actually holds.
- **Mirroring:** on a rig whose left and right rest frames mirror with the local X axis flipped, a rotation (w, x, y, z) maps to (w, x, −y, −z) and a location (x, y, z) to (−x, y, z). Check the rig first: the mirrored left rest pose should match the right one.
- **Matching motion:** to make one limb move as much as another, sample both across the loop relative to the body and compare their ranges, in the engine as well as in Blender. Copying a rotation between limbs can move the copy the wrong way: an upper-arm swing that lifts a hand held forward swings a hanging hand sideways, where a bend at the elbow lifts it.
- **Then look:** `look` with a small `max_size`, at the frames and views `keyframe-coach` describes. Look again only after a visible change.

## Previewing a pose over a clip
- **Pose it over the clip it will play on.** A pose meant for a layer over other clips, such as an arm or a hand pose, replaces only its own bones, so the rest of the body comes from the clip below.
- **To preview,** mute every NLA track except that clip's, and make the pose the active action. Setting a track's `is_solo` from a script didn't take effect; muting does.
- **The engine has the final say.** Blender doesn't show the engine's layer masks, blending, attach points or game camera, so finish with a capture in the engine.

## Checking an export
- **Use the project's own export script or tool** when it has one, and send a check export to a scratch folder, not into the project.
- **Byte for byte:** with the same Blender version, `PYTHONHASHSEED=0` and `--python-use-system-env` (without it, Blender's Python ignores that variable), an FBX re-export of an unchanged file matched the committed export byte for byte. Another patch version differed only in the FBX's `Creator` strings. So a hash proves an edit left the export alone.
- **When a take is added,** compare clips instead. Import both FBXs headless and diff each action's keyframe `co` arrays, which shows whether the existing clips changed at all. Each take's name sits in an FBX binary just before `\x00\x01AnimStack`, so a regex over the bytes lists the takes in file order.
- **Comparing the engine's import with Blender:** evaluate the same frames in both and diff bone positions. In Unity, instantiate the model into `EditorSceneManager.NewPreviewScene()` and drive its clips through a manual `PlayableGraph`, calling `PlayableExtensions` and `PlayableOutputExtensions` statically from `eval`; in headless Blender, `frame_set` each frame and read the pose bones.
- **Partial poses need a mask in the engine.** An exporter that bakes every bone into every take (FBX `bake_anim_use_all_bones`) gives a pose of one arm a pose for the whole body, so the engine layer that plays it needs a mask with only the bones it poses.
- **The engine's default pose can come from a take.** In one Unity project, the model's default pose was the first take's first frame, takes sorted by name. A new action that sorted first would have moved everything computed from that pose, such as camera offsets and attach points. Check which take your engine uses before naming a new one.

## Without the MCP
- **Screenshots of Blender's own UI:** run GUI Blender (not `-b`) with a script that registers a `bpy.app.timers` tick. The tick switches `window.workspace`, then, inside `temp_override(window=win, screen=win.screen)`, calls `bpy.ops.wm.redraw_timer(type="DRAW_WIN_SWAP", iterations=1)` before `bpy.ops.screen.screenshot(filepath=...)`. Without the forced redraw, every shot shows the first frame. Finish by reverting and quitting, as above. macOS has no `timeout`, so run it as a background command that ends when Blender exits.
- **Framing the camera like View › Frame Camera Bounds, without a window,** for a vertically fitted camera: `fac = min(winx / (winy * aspect + 4), winy / (winy + 4))`, `view_camera_zoom = (sqrt(4 * fac) - sqrt(2)) * 50`, offset (0, 0). `winx` and `winy` are the WINDOW region's width and height, and `aspect` is the output resolution's. This matched the operator to 4e-6.
