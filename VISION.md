# Critterbug

Bring forth your inner musician as you and your friends form a band of travelling troubadours and explore the
fascinating world of Critterbug. Marvel at the beauty of this strange and wonderful land and unravel the
stories behind its inhabitants as you pursue your quest for the next meal. And wherever you go, don't forget to
bring your guitar!

## Pillars

- **Music is how you act on the world.** Songs change critters, alter the environment (plants, rocks and more)
  and get you past challenges. Playing is the main verb, not a minigame beside the game.
- **A mystery you unravel by exploring.** In the spirit of Outer Wilds, progress is knowledge, not items. You
  learn the world by exploring it, talking to its critters and singing to them.
- **A band of friends.** Each player plays their own part (instrument) of the same song. Couch co-op comes
  first. Online play comes later, and the code is built with networking in mind from the start.
- **The sound is the heart of it.** Erik's music and sound design carry the game's identity. Tools and formats
  serve that.

## Decisions

- **Engine:** Godot 4, in GDScript.
- **Songs:** stored in the `.chrp` text format. Each song is split into parts with their own audio, and each note
  has a priority that sets difficulty.
- **Each player plays their own part.**
- **Multiplayer:** couch co-op first. Players are separate from their input devices, and song state has one
  authoritative owner, so online play can be added without a rewrite.
- **Cues:** in Story mode you can start any song you know at any time by playing its first few notes. This still
  needs exploring.

## Releases

The plan lives on the Critterbug GitHub project, grouped by its Release field.

| Release | Playable goal |
|---|---|
| 0.1 Core gameplay | One player picks a song and an instrument and plays a whole song that feels good. |
| 0.2 Couch co-op | 2–4 players on one screen each play a part of the same song. |
| 0.3 World building | The band walks around a small 3D area together and meets a critter. |
| 0.4 Songs change the world | One area, one critter, one mystery thread: the right song changes something and opens the way forward. |
| Later | The full story, online play, solos and improvisation, the Steam release. |

## Open questions

- How does the 2D note track sit over the 3D world during a performance?
- How does free play outside a song work, and how are cues recognised in it?
- What does the knowledge journal look like?
- How many players: is it 1–4?
