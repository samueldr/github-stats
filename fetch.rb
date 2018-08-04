#!/usr/bin/env nix-shell
#!ruby # Hack for ruby parsing shebangs.
#!nix-shell -p ruby -i ruby

require "octokit"
require "pp"
require "json"

filename = ARGV.first

client = Octokit::Client.new(
	access_token: "77c2f8d1d5b449d1fad189002cb8c7d39f745694",
	per_page: 100,
)

user = client.user
user.login

client.auto_paginate = true
pulls = client.pulls("nixos/nixpkgs", state: "all")

File.open(filename, "w") do |file|
	file.write(
		JSON.generate(
			pulls.map do |pull|
				{
					id: pull[:id],
					state: pull[:state],
					created_at: pull[:created_at],
					merged_at: pull[:merged_at],
					closed_at: pull[:closed_at],
				}
			end
		)
	)
end
