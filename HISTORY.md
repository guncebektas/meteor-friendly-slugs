HISTORY.md

### v1.0.0
- Forked from [meteor-friendly-slugs](https://github.com/todda00/meteor-friendly-slugs)
- Refactored and modernized
- Compatible with Meteor 3.
- Some features dropped to keep it simple.
- Readme corrected as some features are dropped.

### v0.6.0
 - added ability to create slugs from multiple fields

### v0.5.1
 - additional fixes around nested object cases

### v0.5.0
 - updateSlug is now conditional based on doc, can still be used as boolean
 - Test existing doc for nested fields

### v0.4.0
 - Nested fields are now supported to create slugs from.
 - add slugGenerator option to provide a custom function to generate the slug.
 - added swedish transliterator 'å' -> 'a'

### v0.3.6
 - Added distinctUpTo option to specify what fields need to match in order to make a unique slug

### v0.3.5
 - Added maxLength option to limit slug length, defaults to unlimited

### v0.3.4
 - Apostrophes are now removed prior to creating a slug instead of converting to a hyphen

### v0.3.3
 - Modify documentation about upserts

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
