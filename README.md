# nemo-term-here

A smart Ctrl+Alt+T terminal launcher that opens terminals in the directory of your most recently active Nemo file manager window.

## Features

- **Smart directory detection**: Opens terminal in the directory of your last active Nemo window
- **Fallback behavior**: Opens terminal normally if no Nemo windows are open
- **Default terminal support**: Uses your system's default terminal (Alacritty, gnome-terminal, etc.)
- **Window stacking awareness**: Uses the most recently focused Nemo window, not just the first one

## How It Works

The script uses `xdotool` and X11 properties to:
1. Find all Nemo file manager windows
2. Parse window titles to extract directory paths (requires full path display in Nemo)
3. Determine the most recently active Nemo window using X11 window stacking order
4. Launch your default terminal in that directory

## Requirements

- Linux desktop environment (tested with Cinnamon)
- Nemo file manager
- `xdotool` package
- Nemo configured to show full paths in window titles

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/nemo-term-here.git
   cd nemo-term-here
   ```

2. Make the script executable:
   ```bash
   chmod +x nemo-term-here.sh
   ```

3. Set up the global keyboard shortcut:
   ```bash
   gsettings set org.cinnamon.desktop.keybindings custom-list "['custom0']"
   gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ name "Smart Terminal Launcher (get current nemo dir)"
   gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ command "/path/to/nemo-term-here.sh"
   gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ binding "['<Primary><Alt>t']"
   ```

4. Configure Nemo to show full paths in window titles (File → Preferences → Display → Show full path in title bar)

## Usage

Simply press Ctrl+Alt+T and the terminal will open in the directory of your most recently active Nemo window!

## License

MIT License - see LICENSE file for details.

## Contributing

Pull requests welcome! This script could be enhanced to support other file managers or desktop environments.