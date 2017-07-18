# Build and push documentation on release.

exec = require("child_process").exec
fs = require "fs"
rimraf = require "rimraf"

class DocsBuild
  constructor: (@robot, @gh_user, @gh_email, @gh_token) ->

  canBuild: null

  build: (repo_name, msg) ->
    if false == @canBuild
      msg.send "Build requirements are missing; aborting" if msg
      return
    if null == @canBuild and not @verifyDeps
      msg.send "Build requirements are missing; aborting" if msg
      return

    # Only interested in zendframework repos currently
    [org, repo] = repo_name.split "/"
    if org != "zendframework"
      msg.send "I can only build documentation for zendframework repositories" if msg
      return

    # If a build path already exists, there was an error previously
    if fs.existsSync "/tmp/#{repo}"
      @robot.logger.error "[docs-build] Build path for #{repo} already exists"
      msg.send "It looks like a previous build failed to clean up; aborting." if msg
      return

    msg.send "Preparing to build documentation for #{repo}... I will let you know when I'm done." if msg

    # Clone the repository to a build path
    exec "git clone -b master git://github.com/#{org}/#{repo}.git", {cwd: "/tmp"}, (error, stdout, stderr) =>
      if error
        @robot.logger.error "[docs-build] Error cloning repo #{repo}: #{error}"
        @robot.logger.error "[docs-build] #{stderr}"
        msg.send "It looks like an error occurred cloning the repository #{repo}; aborting." if msg
        return

      # If the repo does not have mkdocs.yml, nothing to do
      if not fs.existsSync "/tmp/#{repo}/mkdocs.yml"
        msg.send "The repository #repo does not have documentation to build." if msg
        @cleanUp repo
        return

      # Clone the mkdocs theme
      exec "git clone git://github.com/zendframework/zf-mkdoc-theme.git", {cwd: "/tmp/#{repo}"}, (error, stdout, stderr) =>
        if error
          @robot.logger.error "[docs-build] Error cloning mkdoc theme: #{error}"
          @robot.logger.error "[docs-build] #{stderr}"
          msg.send "It looks like an error occurred cloning the zf-mkdoc-theme repository; aborting." if msg
          @cleanUp repo
          return

        # Run the build script
        command = "./zf-mkdoc-theme/deploy.sh "
        command += "-n \"#{@gh_user}\" "
        command += "-e \"#{@gh_email}\" "
        command += "-t \"#{@gh_token}\" "
        command += "-r \"github.com/zendframework/#{repo}.git\" "
        command += "-u \"https://docs.zendframework.com/#{repo}\""
        exec command, {cwd: "/tmp/#{repo}"}, (error, stdout, stderr) =>
          if error
            @robot.logger.error "[docs-build] Error running zf-mkdoc-theme deploy.sh: #{error}"
            @robot.logger.error "[docs-build] #{stderr}"
            msg.send "An error occurred while building docs for #{repo}; try again later." if msg
            @cleanUp repo
            return
          # Cleanup when done
          @cleanUp repo
          @robot.logger.info "[docs-build] Built and deployed documentation for #{repo}"
          msg.send "Finished building documentation for #{repo}" if msg

  cleanUp: (repo) ->
    rimraf "/tmp/#{repo}", (error) =>
      return if not error
      @robot.logger.error "[docs-build] Failed to remove directory /tmp/#{repo}: #{error}"

  verifyDeps: () ->
    if not fs.existsSync "/usr/bin/git"
      @canBuild = false
      @robot.logger.error "[docs-build] /usr/bin/git binary not found"
      return false
    if not fs.existsSync "/usr/local/bin/mkdocs"
      @canBuild = false
      @robot.logger.error "[docs-build] /usr/local/bin/mkdocs binary not found"
      return false
    if not fs.existsSync "/usr/bin/php"
      @canBuild = false
      @robot.logger.error "[docs-build] /usr/bin/php binary not found"
      return false
    @canBuild = true
    return true

module.exports = DocsBuild
