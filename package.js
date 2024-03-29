Package.describe({
  name: 'todda00:friendly-slugs',
  version: '1.0.1',
  // Brief, one-line summary of the package.
  summary: 'Generate URL friendly slugs from a field with auto-incrementation to ensure unique URLs.',
  // URL to the Git repository containing the source code for this package.
  git: 'https://github.com/guncebektas/meteor-friendly-slugs',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function (api) {
  api.use(['check', 'matb33:collection-hooks']);
  api.versionsFrom('2.8.1');
  api.addFiles(['slugs.js']);
});
