# Handle the GitHub "status" event
#
# Only handles Travis-CI status at this time. If a pull request context is
# detected, uses the sha1 passed in the event to search for the related pull
# request via the GitHub API in order to display details about the origin of the
# CI build. For normal pushes, simply indicates the build status for the
# repository and the branch that was built.
#
# Usage:
#
# require('../lib/github-status')(robot, room, data, token)
#
# OR
#
# github_status = require '../lib/github-status'
# github_status robot, room, data, token
#
# WHERE
#
# token is the OAuth2 personal access token to use when querying the API.
#
# TODO:
#
# The context for Travis is "continuous-integration/travis-ci/(pr|push)".
# The segment at the end allows us to differentiate between failed builds due to
# a pull request or a _push_ to a branch; this latter will allow us to trigger
# documentation builds once we have a successful "push" build where
# payload.branches[0].name == master.

fetch = require 'node-fetch'

module.exports = (robot, room, payload, token) ->
  return if not payload.state?
  return if not payload.state in ["success", "failure", "error"]
  return if not payload.context.match(/travis-ci/)

  travis_name = "Travis CI"
  travis_icon = "https://a.slack-edge.com/66f9/img/services/travis_36.png"
  travis_link = payload.target_url

  repo = payload.repository.full_name
  ts = new Date payload.updated_at
  ts = new Date ts.getTime()
  ts = Math.floor(ts.getTime() / 1000)

  switch payload.state
    when "success"
      status = "passed"
      color = "good"
    when "failure"
      status = "failed"
      color = "danger"
    when "error"
      status = "errored"
      color = "danger"

  if payload.context.match(/\/pr$/)
    query = encodeURIComponent("repo:#{repo}+#{payload.sha}")
    query = query.replace(/%20/, "+");
    query = query.replace(/%2B/, "+");
    url = "https://api.github.com/search/issues?q=#{query}"
    fetch(url, {headers: {Authorization: "token #{token}"}})
      .then (res) =>
        res.json()
      .then (search) =>
        return if search.incomplete_results
        return if not search.items?.length?
        search.items.forEach (item) =>
          return if not item.pull_request
          fetch(item.pull_request.url, {headers: {Authorization: "token #{token}"}})
            .then (res) =>
              res.json()
            .then (pr) =>
              pr_id = pr.number
              pr_url = pr.html_url
              pr_title = pr.title

              attachment =
                attachments: [
                  fallback: "[#{repo}] Build #{status} for pull request ##{pr_id} #{pr_title}: #{travis_link}"
                  color: color
                  author_name: travis_name
                  author_link: travis_link
                  author_icon: travis_icon
                  text: "<#{travis_link}|Build #{status}> for pull request <#{pr_url}|#{repo}##{pr_id} #{pr_title}>"
                  fields: [
                    {
                      title: "Repository"
                      value: "<https://github.com/#{repo}|#{repo}>"
                      short: true
                    }
                    {
                      title: "Status"
                      value: status
                      short: true
                    }
                    {
                      title: "Pull Request"
                      value: "<#{pr_url}|##{pr_id} #{pr_title}>"
                    }
                  ]
                  footer: travis_name
                  footer_icon: travis_icon
                  ts: ts
                ]

              robot.send room: room, attachment

            .catch (err) =>
              robot.logger.error "Error fetching pull request via #{item.pull_request.url}"
      .catch (err) =>
        robot.logger.error "Error searching for status details using #{url}"
    return

  branch = payload.branches[0].name

  attachment =
    attachments: [
      fallback: "Build #{status} for #{repo}@#{branch} (#{payload.sha.substring(0,8)}): #{travis_link}"
      color: color
      author_name: travis_name
      author_link: travis_link
      author_icon: travis_icon
      text: "<#{travis_link}|Build #{status}> for <#{payload.repository.html_url}|#{repo}>@#{branch} (<#{payload.commit.html_url}|#{payload.sha.substring(0, 8)}>)"
      fields: [
        {
          title: "Repository"
          value: "<https://github.com/#{repo}|#{repo}>"
          short: true
        }
        {
          title: "Status"
          value: status
          short: true
        }
        {
          title: "Branch"
          value: "#{branch} (#{payload.sha.substring(0,8)})"
        }
      ]
      footer: travis_name
      footer_icon: travis_icon
      ts: ts
    ]

  robot.send room: room, attachment
