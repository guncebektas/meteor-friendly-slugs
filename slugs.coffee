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
        slugFrom: [opts]
      }
    opts.slugFrom = [opts.slugFrom] if _.isString opts.slugFrom

    defaults =
      slugFrom: ['name']
      slugField: 'slug'
      distinct: true
      distinctUpTo: []
      updateSlug: true
      createOnUpdate: true
      maxLength: 0
      debug: false
      transliteration: [
        {from: 'àáâäåãа', to: 'a'}
        {from: 'б',      to: 'b'}
        {from: 'ç',      to: 'c'}
        {from: 'д',      to: 'd'}
        {from: 'èéêëẽэе',to: 'e'}
        {from: 'ф',      to: 'f'}
        {from: 'г',      to: 'g'}
        {from: 'х',      to: 'h'}
        {from: 'ìíîïи',  to: 'i'}
        {from: 'к',      to: 'k'}
        {from: 'л',      to: 'l'}
        {from: 'м',      to: 'm'}
        {from: 'ñн',     to: 'n'}
        {from: 'òóôöõо', to: 'o'}
        {from: 'п',      to: 'p'}
        {from: 'р',      to: 'r'}
        {from: 'с',      to: 's'}
        {from: 'т',      to: 't'}
        {from: 'ùúûüу',  to: 'u'}
        {from: 'в',      to: 'v'}
        {from: 'йы',     to: 'y'}
        {from: 'з',      to: 'z'}
        {from: 'æ',      to: 'ae'}
        {from: 'ч',      to: 'ch'}
        {from: 'щ',      to: 'sch'}
        {from: 'ш',      to: 'sh'}
        {from: 'ц',      to: 'ts'}
        {from: 'я',      to: 'ya'}
        {from: 'ю',      to: 'yu'}
        {from: 'ж',      to: 'zh'}
        {from: 'ъь',     to: ''}
      ]

    _.defaults(opts, defaults)

    fields =
      slugFrom: Array
      slugField: String
      distinct: Boolean
      createOnUpdate: Boolean
      maxLength: Number
      debug: Boolean

    if typeof opts.updateSlug != "function"
      if (opts.updateSlug)
        opts.updateSlug = () -> true
      else
        opts.updateSlug = () -> false


    check(opts,Match.ObjectIncluding(fields))

    collection.before.insert (userId, doc) ->
      fsDebug(opts,'before.insert function')
      runSlug(doc,opts)
      return

    collection.before.update (userId, doc, fieldNames, modifier, options) ->
      fsDebug(opts,'before.update function')
      cleanModifier = () ->
        #Cleanup the modifier if needed
        delete modifier.$set if _.isEmpty(modifier.$set)

      #Don't do anything if this is a multi doc update
      options = options || {}
      if options.multi
        fsDebug(opts,"multi doc update attempted, can't update slugs this way, leaving.")
        return true

      modifier = modifier || {}
      modifier.$set = modifier.$set || {}

      #Don't do anything if all the slugFrom fields aren't present (before or after update)
      cont = false
      _.each opts.slugFrom, (slugFrom) ->
        cont = true if stringToNested(doc, slugFrom) || modifier.$set[slugFrom]? || stringToNested(modifier.$set, slugFrom)
      if !cont
        fsDebug(opts,"no slugFrom fields are present (either before or after update), leaving.")
        cleanModifier()
        return true

      #See if any of the slugFrom fields have changed
      slugFromChanged = false
      _.each opts.slugFrom, (slugFrom) ->
        if modifier.$set[slugFrom]? || stringToNested(modifier.$set, slugFrom)
          docFrom = stringToNested(doc, slugFrom)
          if (docFrom isnt modifier.$set[slugFrom]) and (docFrom isnt stringToNested(modifier.$set, slugFrom))
            slugFromChanged = true

      fsDebug(opts,slugFromChanged,'slugFromChanged')

      #Is the slug missing / Is this an existing item we have added a slug to? AND are we supposed to create a slug on update?
      if !stringToNested(doc, opts.slugField) and opts.createOnUpdate
        fsDebug(opts,'Update: Slug Field is missing and createOnUpdate is set to true')

        if slugFromChanged
          fsDebug(opts,'slugFrom field has changed, runSlug with modifier')
          runSlug(doc, opts, modifier)
        else
          #Run the slug to create
          fsDebug(opts,'runSlug to create')
          runSlug(doc, opts, modifier, true)
          cleanModifier()
          return true

      else
        # Don't change anything on update if updateSlug is false
        if opts.updateSlug?(doc, modifier) is false
          fsDebug(opts,'updateSlug is false, nothing to do.')
          cleanModifier()
          return true

        #Don't do anything if the slug from field has not changed
        if !slugFromChanged
          fsDebug(opts,'slugFrom field has not changed, nothing to do.')
          cleanModifier()
          return true

        runSlug(doc, opts, modifier)

        cleanModifier()
        return true

      cleanModifier()
      return true
    return
  runSlug = (doc, opts, modifier = false, create = false) ->
    fsDebug(opts,'Begin runSlug')
    fsDebug(opts,opts,'Options')
    fsDebug(opts,modifier, 'Modifier')
    fsDebug(opts,create,'Create')

    combineFrom = (doc, fields, modifierDoc) ->
      fromValues = []
      _.each fields, (f) ->
        if modifierDoc?
          if stringToNested(modifierDoc, f)
            val = stringToNested(modifierDoc, f)
          else
            val = stringToNested(doc, f)
        else
          val = stringToNested(doc, f)
        fromValues.push(val) if val
      return false if fromValues.length == 0
      return fromValues.join('-')

    from = if create or !modifier then combineFrom(doc, opts.slugFrom) else combineFrom(doc, opts.slugFrom, modifier.$set)

    if from == false
      fsDebug(opts,"Nothing to slug from, leaving.")
      return true

    fsDebug(opts,from,'Slugging From')

    slugBase = slugify(from, opts.transliteration, opts.maxLength)
    return false if !slugBase

    fsDebug(opts,slugBase,'SlugBase before reduction')

    if opts.distinct

      # Check to see if this base has a -[0-9999...] at the end, reduce to a real base
      slugBase = slugBase.replace(/(-\d+)+$/,'')
      fsDebug(opts,slugBase,'SlugBase after reduction')

      baseField = "friendlySlugs." + opts.slugField + ".base"
      indexField = "friendlySlugs." + opts.slugField + ".index"

      fieldSelector = {}
      fieldSelector[baseField] = slugBase

      i = 0
      while i < opts.distinctUpTo.length
        f = opts.distinctUpTo[i]
        fieldSelector[f] = doc[f]
        i++

      sortSelector = {}
      sortSelector[indexField] = -1

      limitSelector = {}
      limitSelector[indexField] = 1

      result = collection.findOne(fieldSelector,
        sort: sortSelector
        fields: limitSelector
        limit:1
      )

      fsDebug(opts,result,'Highest indexed base found')

      if !result? || !result.friendlySlugs? || !result.friendlySlugs[opts.slugField]? || !result.friendlySlugs[opts.slugField].index?
        index = 0
      else
        index = result.friendlySlugs[opts.slugField].index + 1

      defaultSlugGenerator = (slugBase, index) ->
        if index is 0 then slugBase else slugBase + '-' + index

      slugGenerator = opts.slugGenerator ? defaultSlugGenerator

      finalSlug = slugGenerator(slugBase, index)

    else
      #Not distinct, just set the base
      index = false
      finalSlug = slugBase

    fsDebug(opts,finalSlug,'finalSlug')

    if modifier or create
      fsDebug(opts,'Set to modify or create slug on update')
      modifier = modifier || {}
      modifier.$set = modifier.$set || {}
      modifier.$set.friendlySlugs = doc.friendlySlugs || {}
      modifier.$set.friendlySlugs[opts.slugField] = modifier.$set.friendlySlugs[opts.slugField] || {}
      modifier.$set.friendlySlugs[opts.slugField].base = slugBase
      modifier.$set.friendlySlugs[opts.slugField].index = index
      modifier.$set[opts.slugField] = finalSlug
      fsDebug(opts,modifier,'Final Modifier')

    else
      fsDebug(opts,'Set to update')
      doc.friendlySlugs = doc.friendlySlugs || {}
      doc.friendlySlugs[opts.slugField] = doc.friendlySlugs[opts.slugField] || {}
      doc.friendlySlugs[opts.slugField].base = slugBase
      doc.friendlySlugs[opts.slugField].index = index
      doc[opts.slugField] = finalSlug
      fsDebug(opts,doc,'Final Doc')
    return true

  fsDebug = (opts, item, label = '')->
    return if !opts.debug
    if typeof item is 'object'
      console.log "friendlySlugs DEBUG: " + label + '↓'
      console.log item
    else
      console.log "friendlySlugs DEBUG: " + label + '= ' + item

slugify = (text, transliteration, maxLength) ->
  return false if !text?
  return false if text.length < 1
  text = text.toString().toLowerCase()
  _.each transliteration, (item)->
    text = text.replace(new RegExp('['+item.from+']','g'),item.to)
  slug = text
    .replace(/'/g, '')              # Remove all apostrophes
    .replace(/[^0-9a-z-]/g, '-')    # Replace anything that is not 0-9, a-z, or - with -
    .replace(/\-\-+/g, '-')         # Replace multiple - with single -
    .replace(/^-+/, '')             # Trim - from start of text
    .replace(/-+$/, '');            # Trim - from end of text
  if maxLength > 0 && slug.length > maxLength
    lastDash = slug.substring(0,maxLength).lastIndexOf('-')
    slug = slug.substring(0,lastDash)
  return slug

stringToNested = (obj, path) ->
  parts = path.split(".")
  if parts.length==1
    if obj? && obj[parts[0]]?
      return obj[parts[0]]
    else
      return false
  return stringToNested(obj[parts[0]], parts.slice(1).join("."))
