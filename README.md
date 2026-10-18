# Miami Wind Omarchy Theme
An Omarchy theme based on Miami Wind color scheme which is a blend of colors from [Tailwind CSS](https://tailwindcss.com/docs/colors) and Grayscale colors from [Catppuccin Mocha](https://catppuccin.com/) with inspiration from the theme [Miami Nights](https://github.com/monkeytypegame/monkeytype/blob/master/frontend/src/ts/constants/themes.ts) for [Monkeytype](https://www.monkeytype.com). Color Swatches built using [Coolors](https://coolors.co/)

## Installation

```bash
omarchy theme install https://github.com/hanakin/omarchy-miami-wind-theme
```

That installs the colors: `colors.toml` drives the terminals, Hyprland borders, editors and the rest of Omarchy through its templates, alongside the shipped btop and Chromium colors, the icon setting and the backgrounds.

## Extras

These are optional. Pick the ones you want and do them one at a time.

For each step: copy the line, paste it into your terminal, and press Enter.

### Prompt (Starship)

The colored bar above the line where you type.

1. Save your current prompt settings, in case you want them back:

   ```bash
   mv ~/.config/starship.toml ~/.config/starship.toml.bak
   ```

   If it says "No such file or directory", that's fine. Go to step 2.

2. Turn on the Miami Wind prompt:

   ```bash
   ln -s ~/.config/omarchy/themes/miami-wind/starship.toml ~/.config/starship.toml
   ```

3. Open a new terminal window to see it.

### System info (Fastfetch)

The Miami Wind logo and system info screen.

1. Make sure the settings folder exists:

   ```bash
   mkdir -p ~/.config/fastfetch
   ```

2. Save your current settings, in case you want them back:

   ```bash
   mv ~/.config/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc.bak
   ```

   If it says "No such file or directory", that's fine. Go to step 3.

3. Turn on the Miami Wind layout:

   ```bash
   ln -s ~/.config/omarchy/themes/miami-wind/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
   ```

4. Try it:

   ```bash
   fastfetch
   ```

### Icons (Flatery)

The pink icons for folders and apps.

1. Download the icons:

   ```bash
   git clone --depth 1 https://github.com/cbrnix/Flatery ~/Flatery
   ```

2. Make sure the icons folder exists:

   ```bash
   mkdir -p ~/.local/share/icons
   ```

3. Copy the icons into it (all three folders are needed):

   ```bash
   cp -a ~/Flatery/Flatery ~/Flatery/Flatery-Dark ~/Flatery/Flatery-Pink-Dark ~/.local/share/icons/
   ```

4. Delete the download, you don't need it anymore:

   ```bash
   rm -rf ~/Flatery
   ```

5. Close and reopen your apps (like Files) to see the new icons.

### VS Code

Omarchy already colors VS Code to match. For the full [Miami Wind VS Code theme](https://github.com/hanakin/miami-wind-vscode) instead:

1. Install the theme:

   ```bash
   code --install-extension hanakin.miami-wind
   ```

2. Stop Omarchy from switching VS Code back to its own colors every time you change themes. First make the settings folder:

   ```bash
   mkdir -p ~/.local/state/omarchy/toggles
   ```

3. Then turn the switching off:

   ```bash
   touch ~/.local/state/omarchy/toggles/skip-vscode-theme-changes
   ```

4. In VS Code, press `Ctrl+K`, let go, then press `Ctrl+T`. Pick **Miami Wind** from the list.

To let Omarchy color VS Code again later:

```bash
rm ~/.local/state/omarchy/toggles/skip-vscode-theme-changes
```

### Obsidian

Omarchy already colors Obsidian to match. For the full [Miami Wind Obsidian theme](https://github.com/hanakin/miami-wind-obsidian-theme) instead:

1. Go to your vault's folder. Change `~/Documents/MyVault` to where your vault is (in Obsidian, click your vault's name in the bottom left, then **Manage vaults** to see where it is):

   ```bash
   cd ~/Documents/MyVault
   ```

2. Make a folder for the theme:

   ```bash
   mkdir -p ".obsidian/themes/Miami Wind"
   ```

3. Download the theme:

   ```bash
   curl -L -o ".obsidian/themes/Miami Wind/theme.css" https://raw.githubusercontent.com/hanakin/miami-wind-obsidian-theme/main/theme.css
   ```

4. Download the theme's info file:

   ```bash
   curl -L -o ".obsidian/themes/Miami Wind/manifest.json" https://raw.githubusercontent.com/hanakin/miami-wind-obsidian-theme/main/manifest.json
   ```

5. In Obsidian, open **Settings**, then **Appearance**, and pick **Miami Wind** under **Themes**.

### Undo

To go back, delete the link and put your saved file back. For the prompt:

```bash
rm ~/.config/starship.toml
```

```bash
mv ~/.config/starship.toml.bak ~/.config/starship.toml
```

If it says "No such file or directory", you didn't have one before. That's fine.

For Fastfetch:

```bash
rm ~/.config/fastfetch/config.jsonc
```

```bash
mv ~/.config/fastfetch/config.jsonc.bak ~/.config/fastfetch/config.jsonc
```

If it says "No such file or directory", you didn't have one before. That's fine.

## Preview

![Preview](./preview.png)

## Color Palette

## Base Colors
[Primary Colors](https://coolors.co/f472b6-22d3ee-fef08a-c084fc-818cf8-34d399-f87171-fdba74)

![Primary Colors](./imgs/primary-colors.png)

## Additional Colors
[Bright Colors](https://coolors.co/palette/ec4899-38bdf8-fde047-a78bfa-2563eb-4ade80-f43f5e-fb923c)

![Bright Colors](./imgs/bright-colors.png)

## Grayscale

[Text Colors](https://coolors.co/cdd6f4-bac2de-a6adc8)

![Text Colors](./imgs/text-colors.png)

[Overlay Colors](https://coolors.co/9399b2-7f849c-6c7086)

![Overlay Colors](./imgs/overlay-colors.png)

[Surface Colors](https://coolors.co/585b70-45475a-313244)

![Surface Colors](./imgs/surface-colors.png)

[Background Colors](https://coolors.co/1e1e2e-181825-11111b)

![Background Colors](./imgs/background-colors.png)
