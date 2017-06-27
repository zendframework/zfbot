# Retrieve and persist a list of Discourse categories

authorize = require './authorize'

class NullMessage
  send: (message) ->

class DiscourseCategories
  constructor: (@robot, @discourse, @discourse_url) ->

  BRAIN_DISCOURSE_CATEGORIES: "discourse_categories"
  loaded: false
  categories: []

  load: (data) ->
    # this loaded event is sent on each robot.brain.set, skip it after initial load
    return if @loaded

    @loaded = true
    @restoreCategories()

  restoreCategories: ->
    categories = @robot.brain.get(@BRAIN_DISCOURSE_CATEGORIES)
    if categories?.length?
      @categories = categories
      return
    msg = new NullMessage
    @fetchCategories msg

  fetchCategories: (msg) ->
    knownCategoryIds = []
    @categories.forEach (category) ->
      knownCategoryIds.push category.id

    @discourse.getCategories {}, (err, body, httpCode) =>
      if err
        @robot.logger.error "Error response returned when fetching Discourse category list", err
        msg.send "An error occurred fetching the Discourse category list; try again later."
        return

      data = JSON.parse body
      if payload.errors?
        @robot.logger.error "Error fetching Discourse category list", payload.errors
        msg.send "An error occurred fetching the Discourse category list; please notifiy your administrator"
        return

      payload.category_list.categories.forEach (category) =>
        return if category.id in knownCategoryIds
        return if category.has_children
        return if category.read_restricted
        @categories.push {
          id: category.id
          name: category.name
          slug: category.slug
        }

      @robot.brain.set(@BRAIN_DISCOURSE_CATEGORIES, @categories)

      msg.send "Refreshed Discourse category list"

  list: (msg) ->
    return msg.send "No Discourse categories found; run 'discourse refresh'?" if !@categories.length
    categories = ["The following top-level Discourse categories are available:"]
    @categories.forEach (category) ->
      categories.push "- <#{@discourse_url}/c/#{category.slug}|#{category.name}>"

    msg.send categories.join("\n")

module.exports = DiscourseCategories
