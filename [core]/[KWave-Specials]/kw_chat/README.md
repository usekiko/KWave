# DTF Chat - Death Freeroam Edition

A clean, minimalist chat system for FiveM Death Freeroam servers.

## Features

- **Top-Left Position** - Clean placement, doesn't block gameplay
- **Auto-Hide** - Hides after 5 seconds of inactivity
- **Auto-Show** - Shows when new message arrives
- **Command Suggestions** - All server commands (tx, hud, togglehud, etc.)
- **Black & White Design** - Pure minimalist aesthetic
- **Smooth Animations** - Rounded corners, blur effects, shadows

## Design

- **Position**: Top-left corner
- **Colors**: Black & white only
- **Border Radius**: 10px (rounded corners throughout)
- **Shadows**: Soft drop shadows
- **Backdrop**: Blur effect for modern look

## Commands

| Command | Description |
|---------|-------------|
| `/help` | Show help message |
| `/clear` | Clear your chat |
| `/report [id] [reason]` | Report a player |

## All Server Commands

The chat automatically shows ALL commands from your server:
- `/tx` (txAdmin)
- `/hud` (DTF HUD)
- `/togglehud` (DTF HUD)
- `/revive` (Revive system)
- Plus any other commands from your resources

## Controls

| Key | Action |
|-----|--------|
| **T** | Open chat |
| **Enter** | Send message |
| **Escape** | Close chat |
| **Tab** | Autocomplete command |
| **Arrow Up/Down** | Navigate suggestions |

## Installation

Add to `server.cfg`:
```cfg
ensure kw_chat
```

Must be started after any resources that register commands.

## Auto-Hide Behavior

1. Chat is visible when you join
2. After 5 seconds of no new messages, chat fades out
3. When a new message arrives, chat fades in
4. While typing, chat stays visible
5. After closing input, 5-second timer starts again
