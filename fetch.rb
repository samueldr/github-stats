#!/usr/bin/env ruby

require_relative "secrets"
require_relative "db"
require "octokit"
require "pp"
require "json"

filename = ARGV.first

$client = Octokit::Client.new(
	access_token: GITHUB_TOKEN,
	per_page: 100,
)

user = $client.user
user.login

puts "Starting..."
#$client.auto_paginate = true

$client.pulls(
  "nixos/nixpkgs",
  state: "all",
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
  puts "Next: #{last_response.rels[:next].href}"
  last_response = last_response.rels[:next].get
end
