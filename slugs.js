Meteor.Collection.prototype.friendlySlugs = function (options) {
  const collection = this;

  if (options == null) {
    options = {};
  }

  if (typeof options === 'string') {
    options = {
      slugFrom: [options]
    };
  }

  const defaults = {
    slugFrom: ['name'],
    slugField: 'slug',
    isUpdateSlug: true,
  };
  options = {...defaults, ...options};

  if (!Array.isArray(options)) {
    options = [options];
  }

  options.forEach(opts => {
    const fields = {
      slugFrom: Array,
      slugField: String,
      isUpdateSlug: Boolean,
    };

    check(opts, Match.ObjectIncluding(fields));

    collection.before.insert(async function (userId, doc) {
      log('before.insert function');

      await runSlug(doc, opts);
    });

    collection.before.upsert(async function (userId, selector, modifier, options) {
      log('before.upsert function');

      /** region argumentCheck */
      if (options?.multi) {
        log("multi doc update attempted, can't update slugs this way, leaving.");
        return true;
      }

      if (typeof modifier.$set === "undefined") {
        return true;
      }

      if (Object.keys(modifier.$set).length === 0) {
        return true;
      }
      /** endregion argumentCheck */

      /** region isExecutable */
      let isExecutable = false;
      opts.slugFrom.forEach(slugFrom => {
        if (modifier.$set[slugFrom] != null || stringToNested(modifier.$set, slugFrom)) {
          isExecutable = true;
        }
      });

      if (!isExecutable) {
        log("no slugFrom fields are present (either before or after update), leaving.");
        return true;
      }
      /** endregion isExecutable */

      /** region isSlugFromChanged */
      let isSlugFromChanged = false;
      opts.slugFrom.forEach(slugFrom => {
        let docFrom;
        if ((modifier.$set[slugFrom] != null) || stringToNested(modifier.$set, slugFrom)) {
          docFrom = stringToNested(doc, slugFrom);
          if ((docFrom !== modifier.$set[slugFrom]) && (docFrom !== stringToNested(modifier.$set, slugFrom))) {
            isSlugFromChanged = true;
          }
        }
      });

      if (!isSlugFromChanged) {
        log('slugFrom field has not changed, nothing to do.');
        return true;
      }
      /** endregion isSlugFromChanged */

      /** region isExecutable */
      if (opts.isUpdateSlug === false) {
        log('isUpdateSlug is false, nothing to do.');
        return true;
      }
      /** endregion isExecutable */

      await runSlug(modifier, opts);
    });

    collection.before.update(async function (userId, doc, fieldNames, modifier, options) {
      log('before.update function');

      /** region argumentCheck */
      if (options?.multi) {
        log("multi doc update attempted, can't update slugs this way, leaving.");
        return true;
      }

      if (typeof modifier.$set === "undefined") {
        return true;
      }

      if (Object.keys(modifier.$set).length === 0) {
        return true;
      }
      /** endregion argumentCheck */

      /** region isExecutable */
      let isExecutable = false;
      opts.slugFrom.forEach(slugFrom => {
        if (modifier.$set[slugFrom] != null || stringToNested(modifier.$set, slugFrom)) {
          isExecutable = true;
        }
      });

      if (!isExecutable) {
        log("no slugFrom fields are present (either before or after update), leaving.");
        return true;
      }
      /** endregion isExecutable */

      /** region isSlugFromChanged */
      let isSlugFromChanged = false;
      opts.slugFrom.forEach(slugFrom => {
        let docFrom;
        if ((modifier.$set[slugFrom] != null) || stringToNested(modifier.$set, slugFrom)) {
          docFrom = stringToNested(doc, slugFrom);
          if ((docFrom !== modifier.$set[slugFrom]) && (docFrom !== stringToNested(modifier.$set, slugFrom))) {
            isSlugFromChanged = true;
          }
        }
      });

      if (!isSlugFromChanged) {
        log('slugFrom field has not changed, nothing to do.');
        return true;
      }
      /** endregion isSlugFromChanged */

      /** region isUpdateSlug */
      if (opts.isUpdateSlug === false) {
        log('isUpdateSlug is false, nothing to do.');
        return true;
      }
      /** endregion isUpdateSlug */

      await runSlug(doc, opts, modifier);
    });
  });

  const runSlug = async function (doc, opts, modifier) {
    log('Begin runSlug');
    log(opts, 'Options');
    log(modifier, 'Modifier');

    const combineFrom = function (doc, fields, modifierSet) {
      let fromValues = [];

      fields.forEach(function (f) {
        let val;
        if (modifierSet !== null) {
          if (stringToNested(modifierSet, f)) {
            val = stringToNested(modifierSet, f);
          } else {
            val = stringToNested(doc, f);
          }
        } else {
          val = stringToNested(doc, f);
        }

        if (val) {
          fromValues.push(val);
        }
      });

      if (fromValues.length === 0) {
        return false;
      }

      return fromValues.join('-');
    };

    let from = !modifier ? combineFrom(doc, opts.slugFrom) : combineFrom(doc, opts.slugFrom, modifier.$set);
    if (from === false) {
      log("Nothing to slug from, leaving.");
      return true;
    }

    log(from, 'Slugging From');
    let slugBase = slugify(from) || false;
    log(slugBase, 'SlugBase before reduction');
    slugBase = slugBase.replace(/(-\d+)+$/, '');
    log(slugBase, 'SlugBase after reduction');

    let baseField = `friendlySlugs.${opts.slugField}.base`;
    let indexField = `friendlySlugs.${opts.slugField}.index`;

    let fieldSelector = {};
    fieldSelector[baseField] = slugBase;

    let sortSelector = {};
    sortSelector[indexField] = -1;

    let limitSelector = {};
    limitSelector[indexField] = 1;

    let result = await collection.findOneAsync(
      fieldSelector, {
        sort: sortSelector,
        fields: limitSelector,
        limit: 1
      });

    log(result, 'Highest indexed base found');

    let index = 0;

    if (result && result.friendlySlugs && result.friendlySlugs[opts.slugField]) {
      index = (result.friendlySlugs[opts.slugField].index || 0) + 1;
    }

    const finalSlug = slugGenerator(slugBase, index);

    if (modifier) {
      log(`Set to modify the slug on update as ${finalSlug}`);
      modifier.$set = modifier.$set || {};
      modifier.$set.friendlySlugs = doc.friendlySlugs || {};
      modifier.$set.friendlySlugs[opts.slugField] = modifier.$set.friendlySlugs[opts.slugField] || {};
      modifier.$set.friendlySlugs[opts.slugField].base = slugBase;
      modifier.$set.friendlySlugs[opts.slugField].index = index;
      modifier.$set[opts.slugField] = finalSlug;
      log(modifier, 'Final Modifier');
    } else {
      log(opts, 'Set to update');
      doc.friendlySlugs = doc.friendlySlugs || {};
      doc.friendlySlugs[opts.slugField] = doc.friendlySlugs[opts.slugField] || {};
      doc.friendlySlugs[opts.slugField].base = slugBase;
      doc.friendlySlugs[opts.slugField].index = index;
      doc[opts.slugField] = finalSlug;
      log(opts, doc, 'Final Doc');
    }
  };
};

const log = (item, label) => {
  return false; // enable this to disable log

  if (label == null) {
    label = '';
  }

  if (typeof item === 'object') {
    log(`friendly-slugs [DEBUG] ${label} ↓`);
    log(item);
  } else {
    log(`friendly-slugs [DEBUG] ${label} = ${item}`);
  }
};

const slugGenerator = (slugBase, index) => {
  if (index === 0) {
    return slugBase;
  }

  return `${slugBase}-${index}`;
};

const slugify = (text) => {
  if (text == null) {
    return false;
  }

  if (text.length < 1) {
    return false;
  }

  text = text.toString().toLowerCase();

  const transliterations = [
    {
      from: 'àáâäåãа',
      to: 'a'
    }, {
      from: 'б',
      to: 'b'
    }, {
      from: 'ç',
      to: 'c'
    }, {
      from: 'д',
      to: 'd'
    }, {
      from: 'èéêëẽэе',
      to: 'e'
    }, {
      from: 'ф',
      to: 'f'
    }, {
      from: 'г',
      to: 'g'
    }, {
      from: 'х',
      to: 'h'
    }, {
      from: 'ıìíîïи',
      to: 'i'
    }, {
      from: 'к',
      to: 'k'
    }, {
      from: 'л',
      to: 'l'
    }, {
      from: 'м',
      to: 'm'
    }, {
      from: 'ñн',
      to: 'n'
    }, {
      from: 'òóôöõо',
      to: 'o'
    }, {
      from: 'п',
      to: 'p'
    }, {
      from: 'р',
      to: 'r'
    }, {
      from: 'сş',
      to: 's'
    }, {
      from: 'т',
      to: 't'
    }, {
      from: 'ùúûüу',
      to: 'u'
    }, {
      from: 'в',
      to: 'v'
    }, {
      from: 'йы',
      to: 'y'
    }, {
      from: 'з',
      to: 'z'
    }, {
      from: 'æ',
      to: 'ae'
    }, {
      from: 'ч',
      to: 'ch'
    }, {
      from: 'щ',
      to: 'sch'
    }, {
      from: 'ш',
      to: 'sh'
    }, {
      from: 'ц',
      to: 'ts'
    }, {
      from: 'я',
      to: 'ya'
    }, {
      from: 'ю',
      to: 'yu'
    }, {
      from: 'ж',
      to: 'zh'
    }, {
      from: 'ъь',
      to: ''
    }
  ];
  transliterations.forEach(item => {
    text = text.replace(new RegExp(`[${item.from}]`, 'g'), item.to);
  });

  return text
  .replace(/'/g, '')
  .replace(/[^0-9a-z\s-]/g, '')
  .replace(/\s+/g, '-')
  .replace(/-+/g, '-')
  .replace(/^-+/, '')
  .replace(/-+$/, '');
};

const stringToNested = (obj, path) => {
  let parts = path.split(".");

  if (parts.length === 1) {
    if ((obj != null) && (obj[parts[0]] != null)) {
      return obj[parts[0]];
    }

    return false;
  }

  return stringToNested(obj[parts[0]], parts.slice(1).join("."));
};
