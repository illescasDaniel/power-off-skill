# power-off

Powers off the machine once a long-running task is done, on Linux, macOS, Windows and WSL. It only runs when you
explicitly ask ("power off after finishing", "shut down when done"); the agent never decides to do it on its own.

It is an [Agent Skill](https://agentskills.io) (a `SKILL.md` plus two small scripts), so it works in Claude Code,
Cursor and any other agent that loads skills.

## How it works

1. **Trigger check**: only your own message in the conversation counts as a request.
2. **Pick the mode** from your words: *default* (always powers off, even if the task failed or a decision is
   pending), or *or-sleep* if you add "or sleep if you need me" (or run `/power-off or-sleep`; `or-suspend` works too).
3. **Finish first**: a failed task is retried once. Then:

   | Situation | Default | or-sleep |
   |---|---|---|
   | Task done | power off | power off |
   | Task failed (retried once, failed again) | power off | power off, or **sleep** if the failure leaves things the user should look at first |
   | Agent needs a decision from the user | power off | **sleep**, so it resumes when you are back |
   | Powering off seems unwise (unsaved or half-finished work outside the task, a risky state) | power off | **sleep** |
   | Remote machine (SSH), other users logged in, or WSL | asks first, no shutdown | asks first, no shutdown |
   | Power-off command fails | retries once, then **sleep** | retries once, then **sleep** |
   | Sleep also fails | machine stays on, nothing more to try | machine stays on, nothing more to try |

   The report is written to a file first, since the session dies at shutdown.
4. **Safety check**: it asks first on remote machines (SSH), when other users are logged in, and on WSL (where the
   command powers off the Windows host), in both modes.
5. **Shutdown**: `scripts/power-off.sh [--sleep]` (or `power-off.ps1 [-Sleep]`) detects the OS, waits 5 seconds (so
   the agent can finish its reply) and runs the graceful command, retrying once and then falling
   back to sleep if that fails. No OS force flags.

| OS | Power off | Sleep |
|---|---|---|
| Linux | `systemctl poweroff` | `systemctl suspend` |
| macOS | `osascript -e 'tell app "System Events" to shut down'` | `pmset sleepnow` |
| Windows | `shutdown /s /t 0` | `rundll32.exe powrprof.dll,SetSuspendState 0,1,0` |
| WSL | `shutdown.exe /s /t 0` | same `rundll32.exe` call |

Try it safely with `sh skills/power-off/scripts/power-off.sh --dry-run`.

## Install

### Any agent: the `skills` CLI

```bash
npx skills add illescasDaniel/power-off-skill
```

It asks which agents to install for and whether to install into the current project or globally. Non-interactive:
`npx skills add illescasDaniel/power-off-skill -a claude-code -y`, plus `-g` for global.

### By hand

Copy the `skills/power-off` folder into your agent's skills directory.

| | Project (shared with your team) | All your projects |
|---|---|---|
| Codex | `.agents/skills/power-off/` | `~/.agents/skills/power-off/` |
| Claude Code | `.claude/skills/power-off/` | `~/.claude/skills/power-off/` |
| Cursor | `.cursor/skills/power-off/` | `~/.cursor/skills/power-off/` |

## Contributing

Issues and pull requests are welcome. The skill is deliberately short: if a change makes `SKILL.md` longer, it should
earn it.

## License

MIT, see [LICENSE](LICENSE).
