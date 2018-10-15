#!/usr/bin/env ruby

#
# Big hacky script that will cache locally the nixpkgs pull requests listing.
#
# It can refresh modified pull requests if given `--update` as a parameter.
#

require "bundler/setup"    # Using bundler
require "octokit"          # GitHub API helper
require_relative "secrets" # Sneaky trick!
require_relative "db"      #

# FIXME : more clever arguments parsing.
$only_update = ARGV.first == "--update"

# This is pretty hardcoded; nothing in the cache will
# work with more than one repository.
REPO = "NixOS/nixpkgs"

# Debug print
def dbgp(*args)
  puts [" [D]", *args].join(" ")
end

# Helper function, given a block, it will pause its execution until
# it is possible to do the request.
def work()
  # FIXME : .rel[...].get doesn't update $client.rate_limit...

  rate_limit = $client.rate_limit
  dbgp "#{rate_limit.remaining} API calls left."

  # A little buffer in case we use a feature from octokit
  # which doesn't update rate_limit on `$client`.
  if rate_limit.remaining < 5 then
    reset = rate_limit.resets_in + 10
    puts "💤 zleepy timez (back in #{reset} seconds)"
    sleep(reset)
  end

  yield
end

# Oh eww, a global variable!
# Did I say this is a hack?
$client = Octokit::Client.new(
	access_token: GITHUB_TOKEN,
	per_page: 100,
)

puts "Logging-in..."
work { $client.user.login }

params = {
  # All results (closed AND open)
  state: "all",
}

if $only_update then
  # Find when the last update was written.
  latest_update = $db
    .execute("SELECT updated_at FROM pulls ORDER BY updated_at DESC LIMIT 1")
    &.first&.first
  params[:direction] = "desc"
  params[:sort] = "updated"
else
  # When filling from the beginning, it is safer to work from the older to the
  # newer; things won't shift into pages.
  params[:direction] = "asc"
end

# https://developer.github.com/v3/pulls/#list-pull-requests
# Start querying for stuff!
puts "Starting..."
work { $client.pulls(REPO, **params) }

# Work variable. This is used to page through results.
current_results = $client.last_response
continue = true

loop do
  # Mapping through PRs.
  current_results.data.map do |pull|
    number = pull[:number]
    puts "Doing PR ##{number}"

    DB.replace_pull(pull)
    work {$client.get(pull.commits_url)}.map do |commit|
      DB.replace_commit(number, commit)
    end

    # This is a bit "dangerous" as with a failed partial refresh it would leave
    # a new "updated_at" value with a gap in the data.
    # The real solution is to instead reverse the direction (asc) and limit the
    # search query using >= latest_update
    if $only_update then
      if latest_update and pull[:updated_at].to_s < latest_update then
        puts "Finished with the partial update..."
        continue = false
        break
      end
    end
  end

  # Breaking from the previous loop?
  break unless continue

  # At the end of the results set? yay! no need to work any further.
  break unless current_results.rels[:next]

  puts "Next: #{current_results.rels[:next].href}"
  current_results = work { current_results.rels[:next].get }
end

puts ""
puts " 🎉  All done!"
