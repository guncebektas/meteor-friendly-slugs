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

    _.defaults(opts, defaults)

    collection.before.insert (userId, doc) ->
      slugBase = slugify(doc[opts.slugFrom])

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

      doc.friendlySlugs = doc.friendlySlugs || {}
      doc.friendlySlugs[opts.slugField] = doc.friendlySlugs[opts.slugField] || {}
      doc.friendlySlugs[opts.slugField].base = slugBase
      doc.friendlySlugs[opts.slugField].index = index
      doc[opts.slugField] = finalSlug

slugify = (text) ->
  return text.toString().toLowerCase()
    .replace(/\s+/g, '-')           # Replace spaces with -
    .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
    .replace(/\-\-+/g, '-')         # Replace multiple - with single -
    .replace(/^-+/, '')             # Trim - from start of text
    .replace(/-+$/, '');            # Trim - from end of text