#!/usr/bin/env ruby

require_relative "secrets"
require_relative "db"
require "faraday-http-cache"
require "octokit"
require "pp"
require "json"

# https://github.com/octokit/octokit.rb#caching
# Tries to reduce issues with rate limits.
stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

$client = Octokit::Client.new(
	access_token: GITHUB_TOKEN,
	per_page: 100,
)
$client.middleware = stack
user = $client.user
user.login

puts "Starting..."
#$client.auto_paginate = true

# https://developer.github.com/v3/pulls/#list-pull-requests
$client.pulls(
  "nixos/nixpkgs",
  state: "all",
  sort: "updated",
  direction: "desc",
  # page: 30,
)
last_response = $client.last_response
loop do
  pulls = last_response.data
  puts "Mapping pull requests"
  pulls.map do |pull|
    number = pull[:number]
    puts "Doing PR ##{number}"

    DB.replace_pull(pull)
    $client.get(pull.commits_url).map do |commit|
      DB.replace_commit(number, commit)
    end
  end

  break unless last_response.rels[:next]
  # FIXME : if rate limit exceeded, check headers and wait
  # https://developer.github.com/v3/#rate-limiting
  puts "Next: #{last_response.rels[:next].href}"
  last_response = last_response.rels[:next].get
end
