Koreader patch to save your refresh rate settings per filetype. 

For example: set "Every chapter" for EPUB and "Every 6 pages" for CBZ, and each type keeps its own value every time you open a file.

## Install

1. Copy 2-refresh-per-filetype.lua into koreader's patches folder. 
2. Restart KOReader.

## Notes

- The first time a type is opened, the current value is saved as its starting point.
- Settings are stored in settings/refresh_per_filetype.lua.
- Only the refresh rate is covered, not the "flash on chapter boundaries" or "flash on pages with images" toggles.
