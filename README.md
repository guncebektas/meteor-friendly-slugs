# URL Friendly slugs for Meteor

This package has two main purposes:

1. Make it easy to create a sanitized and URL friendly slug based off of an existing field or fields.
2. Auto-increment the slug if needed to ensure each item has a unique URL

## Features

- Automatically assign a URL friendly slug based on a field or fields of your specification. The slug will be sanitized following these rules:
    - Uses all lowercase letters
    - Transliterates accented and other variants (see [Transliteration](#transliteration))
    - Replace spaces with -
    - Removes apostrophes
    - Replace anything that is not 0-9, a-z, or - with -
    - Replace multiple - with single -
    - Trim - from start of text
    - Trim - from end of text
- Checks other items in the collection for the same slug, adds an auto-incrementing index to the end if needed. For example if a slug is based of a field who's value is "Foo Bar" and there is another item with the same value, the new slug will be 'foo-bar-1'.
- Can create slugs for multiple fields, and from multiple fields.
- Can optionally create a slug without the auto-incrementing index.
- Can optionally update a slug when the field it is based from is updated.
- Do all of these things efficiently, storing the base and index for a quick query

## Installation

```
meteor add guncebektas:friendly-slugs
```

## Usage

After you define your collection with something like:

```
Collection = new Mongo.Collection("collection");
```

You can call the friendlySlugs function a few different ways:

### No options

```
Collection.friendlySlugs();
```

This will look for a field named 'name' and create a slug field named 'slug'

### Specify field only

```
Collection.friendlySlugs('name');
```

This will create a 'slug' field based off of the field you specify

### Include any options

```
Collection.friendlySlugs(
  {
    slugFrom: 'name',
    slugField: 'slug',
    distinct: true,
    updateSlug: true
  }
);
```

These are the default values, include what you would like to change

### Slug Multiple Fields

```
Collection.friendlySlugs([
  {
    slugFrom: 'name',
    slugField: 'slug',
  },
  {
    slugFrom: ['profile.firstName', 'profile.lastName'],
    slugField: 'slug2',
  }
]);
```

Each field specified will create a slug to the slug field specified.

### Options

| Option       | Default | Description                                                                                                                                                                                                                                                                       |
|--------------|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| slugFrom     | 'name'  | Name of field (or array of names) you want to base the slug from. Does support nested fields using dot notation for example "profile.name" If an array is provided slug will be built from field values separated by '-' in the order they appear in the array. *String or Array* |
| slugField    | 'slug'  | Name of field you want the slug to be stored to. This can be a nested field. *String*                                                                                                                                                                                             |
| isUpdateSlug | true    | True = Update the item's slug if the slugField's content changes in an update. False = Slugs do not change when the slugField changes. Also can provide a function (doc,modifier) which returns true or false *Boolean or Function*                                               |

### Transliteration

If you want to change/add something you can create a local copy of the package. If you think it's a general usage, please make PR. I will merge general usages into the package core.

For the slug part of the URL, we are only allowing a-z, 0-9, and -
This keeps in accordance with [RFC 1738](http://www.rfc-editor.org/rfc/rfc1738.txt) explained [here in a more helpful way](http://www.blooberry.com/indexdot/html/topics/urlencoding.htm)

### Updates Using multi=true
This package will not update slugs for Documents when an update is for multiple documents (multi=true)
When I was attempting to get these to work right, it kept using the slug from the first document for all subsequent documents. If you wish to work on this issue, a PR would be welcome.

### Creating Slugs in Bulk for Existing Documents
It will drain you resources as it'll generate slugs one-by-one, so use it wisely.

### Improvements / Bugs and Fixes
This is a pretty good package, and I'm using it in production. But, I'm only creating one slug from one field. My usage is deadly simple and the package works fine for me. However, I will be glad to fix bugs on edge cases. Let me know if something isn't working for your use case.

Feedback and PRs are welcome.
