# Retrieve information on a single Discourse category
#
# Checks the robot.brain for categories, and then attempts to match the
# requested category identifier to one that's known.

_ = require "lodash"
categories = require "./discourse-categories"

default_category = {
    name: "Uncategorized"
    slug: "uncategorized"
    id: 1
}

module.exports = (robot, category_id) ->
  robot.logger.info "Looking for #{category_id} in categories", categories
  if not categories?.length
    robot.logger.error "Discourse categories have not been loaded?"
    return default_category

  category = _.find categories, (data) ->
    return data.id == category_id

  return default_category if not category
  return category
