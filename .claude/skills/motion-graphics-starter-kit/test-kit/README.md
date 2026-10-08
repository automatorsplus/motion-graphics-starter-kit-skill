# Test kit: run the same prompt on two models

Is the dearer model worth it for motion graphics on your setup? Run one prompt on two models and compare the
films and the bills. About ten minutes of your time; the models do the rest.

## Keep it fair

The point is that only the model changes.

1. **Two fresh sessions.** Open a new Claude Code session for each run, in the same project, so both see the same
   files, skills and keys and neither remembers the other.
2. **Same model settings except the model.** In each session type `/model` and pick the model, then `/effort` and
   pick the SAME effort level for both (medium is a good default).
3. **Same prompt, word for word.** Copy one from `../examples/` and fill the brackets once, then paste the identical
   text into both sessions. Only the output folder may differ: add *Save it in films/model-a/* to one and
   *films/model-b/* to the other.
4. **One shot.** No notes, no second rounds. The first render is the result.
5. **Judge blind.** Ask someone to rename the two MP4s to A and B before you watch, and pick before you look at
   which is which.

## What each run cost

Every Claude Code session writes a log on your machine. This reads them:

```bash
python3 .claude/skills/motion-graphics-starter-kit/test-kit/cost_from_logs.py --latest 2
```

Run it from the project folder the sessions ran in. It shows each session's model, replies, tokens, wall time and
token cost. The prices are list prices from the Anthropic pricing page dated inside the script: check the page
and update them if they have changed. Output tokens are estimated (the log undercounts them), so treat the cost
as close, not exact. Music on fal.ai is not in the log: add $0.60 for each run that generated music.

## What to compare

- **Looks:** your blind pick, and why in one line.
- **Cost:** token cost from the script, plus any fal.ai spend.
- **Time:** wall time from the script.
- **Replies:** more replies means a bigger bill, because every reply re-reads the whole session so far.
