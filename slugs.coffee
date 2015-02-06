# backwards compatibility
if typeof Mongo is "undefined"
  Mongo = {}
  Mongo.Collection = Meteor.Collection

Mongo.Collection.prototype.friendlySlugs = (options = {}) ->
  collection = @

  if !_.isArray(options)
    options = [options] 

  _.each options, (opts) ->

    if _.isString(opts)
      opts = {
        slugFrom: opts
      }

    defaults = 
      slugFrom: 'name'
      slugField: 'slug'
      distinct: true
      updateSlug: true
      createOnUpdate: true
      debug: false

    _.defaults(opts, defaults)

    fields =
      slugFrom: String
      slugField: String
      distinct: Boolean
      updateSlug: Boolean
      createOnUpdate: Boolean
      debug: Boolean

    check(opts,Match.ObjectIncluding(fields))

    collection.before.insert (userId, doc) ->
      runSlug(doc,opts)
    
    collection.before.update (userId, doc, fieldNames, modifier, options) ->
      modifier = modifier || {}
      modifier.$set = modifier.$set || {}
      modifier.$set[opts.slugFrom] = modifier.$set[opts.slugFrom] || false

      #Don't do anything if the slugFrom field isn't present (before or after update)
      return true if !doc[opts.slugFrom]? and !modifier.$set[opts.slugFrom]?

      #See if the slugFrom has changed
      slugFromChanged = doc[opts.slugFrom] isnt modifier.$set[opts.slugFrom]

      #Is the slug missing / Is this an existing item we have added a slug to? AND are we supposed to create a slug on update?
      if !doc[opts.slugField]? and opts.createOnUpdate

        if slugFromChanged
          runSlug(doc, opts, modifier)
        else
          #Run the slug to create 
          runSlug(doc, opts, modifier, true)

      else
        # Don't change anything on update if updateSlug is false
        return true if opts.updateSlug is false

        #Don't do anything if the slug from field has not changed
        return true if doc[opts.slugFrom] is modifier.$set[opts.slugFrom]

        runSlug(doc, opts, modifier)

  runSlug = (doc, opts, modifier = false, create = false) ->
    from = if modifier and !create then modifier.$set[opts.slugFrom] else doc[opts.slugFrom]

    slugBase = slugify(from)
    return false if !slugBase

    if opts.distinct
      baseField = "friendlySlugs." + opts.slugField + ".base"
      indexField = "friendlySlugs." + opts.slugField + ".index"

      fieldSelector = {}
      fieldSelector[baseField] = slugBase
      
      sortSelector = {}
      sortSelector[indexField] = -1

      limitSelector = {}
      limitSelector[indexField] = 1
      
      result = collection.findOne(fieldSelector,
        sort: sortSelector
        fields: limitSelector
        limit:1
      )

      if !result? || !result.friendlySlugs? || !result.friendlySlugs[opts.slugField]? || !result.friendlySlugs[opts.slugField].index?
        index = 0
      else
        index = result.friendlySlugs[opts.slugField].index + 1

      if index is 0
        finalSlug = slugBase
      else
        finalSlug = slugBase + '-' + index
    else
      #Not distinct, just set the base
      index = false
      finalSlug = slugBase

    if modifier or create
      modifier = modifier || {}
      modifier.$set = modifier.$set || {}
      modifier.$set.friendlySlugs = doc.friendlySlugs || {}
      modifier.$set.friendlySlugs[opts.slugField] = modifier.$set.friendlySlugs[opts.slugField] || {}
      modifier.$set.friendlySlugs[opts.slugField].base = slugBase
      modifier.$set.friendlySlugs[opts.slugField].index = index
      modifier.$set[opts.slugField] = finalSlug

    else
      doc.friendlySlugs = doc.friendlySlugs || {}
      doc.friendlySlugs[opts.slugField] = doc.friendlySlugs[opts.slugField] || {}
      doc.friendlySlugs[opts.slugField].base = slugBase
      doc.friendlySlugs[opts.slugField].index = index
      doc[opts.slugField] = finalSlug    

slugify = (text) ->
  return false if !text?
  return false if text.length < 1
  return text.toString().toLowerCase()
    .replace(/\s+/g, '-')           # Replace spaces with -
    .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
    .replace(/\-\-+/g, '-')         # Replace multiple - with single -
    .replace(/^-+/, '')             # Trim - from start of text
    .replace(/-+$/, '');            # Trim - from end of text