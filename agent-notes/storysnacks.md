# Storysnacks Notes

## Project Overview
- Repository: `drewdrewthis/storysnacks`
- Description: Story writing/generation platform with episodes, drafts, user profiles
- Tech: Node.js, React, AI-powered story generation

## Preferred Status Format
**Kanban Organization:**
- 🎯 **Ready to Work**: Active priorities (2 items max)
- 📋 **Backlog**: Planned features (11+ items)
- ✅ **Done**: Completed work (20+ items)

**Example:**
```
🎯 Ready to Work (2 items):
- Multilingual support (#41)
- Should Not Regenerate Published Episode Versions (#66) - *P0 priority*

📋 Backlog (11 items):
- Create user profiles (#25)
- Public profile pages (#26)
- @Mentions functionality (#27)
...

✅ Done (20 items):
- SSR implementation, mobile fixes, loading UX, story generation performance...
```

## Key Issues Tracked (Updated Dec 6, 2025)
### P0 - Launch Blockers (8 items)
- Auto-generate titles & descriptions on create (#122)
- Published episodes are immutable (#66)
- First-run welcome modal + help button (#123)
- Core write → tweak → publish → continue flow (#124)
- Replace "Discover" with "Library" (#125)
- Mobile readability & tap-target pass (#126)
- Basic loading/error/empty states (#127)
- Minimal "What is this / Privacy" modal (#128)
- Draft autosave on change (#32)
- Block non-author episode creation (#31)

### P1 - Important but can slip (4 items)
- Rename "series" → "story" (#30)
- Delete story/episode/comment (#17, #18, #19)
- Minimal notifications: email for followed stories (#129)
- Simple feedback entry (#85)
- Clean up "request changes" flow (#130)

### P2 - Later / nice-to-have (7 items)
- Multilingual support (#41)
- User profiles & public pages (#25, #26)
- @Mentions in comments (#27)
- Bible creation timing (#29)
- Audio polish / TTS voice + volume controls (#131)
- Cover images for stories (#132)
- Story preferences panel with settings indicator and custom instructions (#133)
  - Convert "additional instructions" on create page to "story preferences" panel
  - Add numbered indicator showing count of enabled settings
  - Include text area for session-specific custom instructions applied to every submission
  - Store all preferences in browser session storage
- Story preferences panel with settings indicator and custom instructions (#133)

## Recent Activity
- Last updated: Dec 6, 2025
- 10 P0 launch blockers identified and prioritized
- 4 P1 important features for post-launch
- 7 P2 nice-to-have features for future
- All issues now have proper priority labels and detailed acceptance criteria