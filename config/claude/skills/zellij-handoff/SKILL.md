---
name: zellij-handoff
description: Run a command the user has to drive or watch themselves in a floating zellij pane that waits for their Enter, then read its exit code and output back without them pasting anything. Use this inside zellij ($ZELLIJ set) whenever you would otherwise tell the user to "run this in another terminal" or suggest `! <command>` for something interactive. That covers sudo or any password prompt, logins and auth flows, TUIs, commands with live output the user needs to watch, and long-running dev servers. Also invoked by the user as /zellij-handoff <command>.
argument-hint: "[command]"
---

# Zellij handoff

When the user needs to run a command themselves, don't ask them to open a pane and paste it. Open a floating command pane that is **suspended**: the command is loaded but doesn't run until the user presses Enter. That Enter is their confirmation that they're ready, so always pass `-s` (`--start-suspended`) on a handoff. Drop it only for a pane you open to test something yourself.

Reach for this instead of your Bash tool when the command:
- prompts for input: `sudo`, passwords, passphrases, confirmations, logins and OAuth flows
- is a TUI or needs a real terminal
- has output the user needs to watch live
- should keep running after your tool call ends, like a dev server or a watcher

If `$ZELLIJ` is unset, fall back to printing the command, or suggest `! <command>` for short non-interactive ones.

If the user invoked this with arguments (`/zellij-handoff <command>`), hand off exactly that command, picking the mode below.

## Pick a mode

**Result to read** (builds, tests, benchmarks, anything that needs sudo): the user watches it run, you get the exit code and output.

```sh
zellij action new-pane -f -s --block-until-exit --cwd "$PWD" -n "claude: <purpose>" \
  -- zsh -c 'setopt pipefail; <cmd> 2>&1 | tee <log>'
```

**Fire-and-done** (logins, TUIs, anything whose exit means "finished" and leaves nothing to read): add `-c` (`--close-on-exit`) so the pane disappears when it ends. Keep the `tee` if you want the output anyway.

**Long-running server**: no `--block-until-exit`, no `-c`. Capture the id so you can read or close it later:

```sh
id=$(zellij action new-pane -f -s --cwd "$PWD" -n "claude: <purpose>" -- <cmd> <args>)
```

## Rules

- Run any `--block-until-exit` call with Bash `run_in_background: true`. It blocks until the user presses Enter **and** the command exits, which can take longer than any tool timeout; you're notified when it returns. Carry on with other work meanwhile.
- The call's exit status is the command's exit status. `setopt pipefail` stops `tee` masking it.
- A command pane is not a shell: pipes, `&&`, `~`, globs and env expansion need the `zsh -c '…'` wrapper.
- `<log>`: a fresh file per handoff in a scratch location (the repo's gitignored `tmp/` if it has one, else the session scratchpad), e.g. `tmp/handoff-build.log`. Read it yourself when the call returns; never ask the user to paste output.
- Use paths that resolve from `--cwd`. Build binaries beforehand so the pane doesn't sit compiling.
- `-n` names the pane; that name is how you find it again.

Then tell the user in one line what's waiting in the floating pane, what to have ready before pressing Enter, and what to watch for.

## Afterwards

- Blocking mode prints no pane id. Find a pane by name: `zellij action list-panes | grep 'claude: <purpose>'`.
- Read a live pane's screen: `zellij action dump-screen --pane-id <id> --full`.
- **Close every pane as soon as you've read its result**, in the same turn: `zellij action close-pane --pane-id <id>`. Don't keep one open "for a re-run"; if another run is needed, open a fresh handoff. Only servers stay open, until the user says to stop them.
