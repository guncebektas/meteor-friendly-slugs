HISTORY.md

### v0.3.2
 - Add modifier cleanup code at all exit points to avoid $set empty errors

### v0.3.1
 - Added 'check' package dependency via PR #4
 - Added russian characters to default transliteration via PR #7
 - Fixed empty $set errors, fixing #5 and #6

### v0.3.0
 - Fixed issue #3 - Slugs aren't guaranteed to be unique

### v0.2.1
 - Fixed bug when checking for options.multi when options is not set

### v0.2.0
 - Added transliteration option to convert accented and other variant characters to the closest english equivelant.

### v0.1.3
 - Added debug logging and fixed some logic issues when adding slugs to existing items

### v0.1.2
 - Added check to not try to slug an empty string

### v0.1.1
  - Will now create slugs for items during an update if a slug is not present
  - Added createOnUpdate option

### v0.1.0
  - Initial Package
