# Jump Maps Tiers Info

This plugin automatically fetches tier information for the current jump map from the Tempus API and displays it to players when they join the server or when they use the `!tier` command. Tiers are color-coded based on difficulty for better visual representation.

## Requirements

- SourceMod 1.10 or newer
- [RipExt Extension](https://github.com/ErikMinekus/sm-ripext) (for HTTP requests and JSON parsing)

## Installation

1. Ensure you have the required extensions installed
2. Download the latest release from the [releases page](https://github.com/electricservers/jump-maps-tiers-info/releases)
3. Extract the contents to your server's `addons/sourcemod` directory
4. Restart your server or load the plugin with `sm plugins load jump_maps_tiers_info`

## Commands

- `!tier` - Displays the current map's soldier and demoman tiers

## Translations

The plugin supports translations. Edit the `translations/maptiersinfo.phrases.txt` file to customize messages in different languages.