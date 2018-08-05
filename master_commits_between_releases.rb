#!/usr/bin/env ruby

require "bundler/setup"
require_relative "db"
require "json"
require "pp"

pull_commits = $db.execute("SELECT sha FROM pull_commits;").map { |row| row.first }


pull_commits.concat(merge_commit_shas)


# I hate to hardcode this, but I want to work in this project's CWD.
# May instead look for an environment variable or config file.
REPO_LOCATION = File.join(ENV["HOME"], "tmp", "nixpkgs", "nixpkgs")
merge_commit_shas = $db.execute("SELECT merge_commit_sha FROM pulls WHERE merge_commit_sha NOT NULL").map(&:first)

pull_commits.concat(merge_commit_shas)

def last_on_master(rel)
  Dir.chdir(REPO_LOCATION) do
    [`git log --format=%H master..origin/release-#{rel} | tail -1`.strip, "^1"].join()
  end
end

def get(a, b)
  Dir.chdir(REPO_LOCATION) do
    `git log --no-merges --pretty=format:"%H" #{last_on_master(a)}..#{last_on_master(b)}`
  end
    .split("\n")
end

def cherry_picked(a, b)
  Dir.chdir(REPO_LOCATION) do
    `git log --pretty=format:%H --grep "picked from commit [0-9a-f]\\+" #{last_on_master(a)}..#{last_on_master(b)}`
  end
    .split("\n")
end

RELEASES = [
  #"15.09",
  #"16.03",
  #"16.09",
  #"17.03",
  "17.09",
  "18.03",
  #"18.09", # not yet!
]

ranges = RELEASES[0..-2].zip(RELEASES[1..-1])

def percentage(a, b)
  (a.to_f / b * 100).round(2)
end

ranges.each do |(a,b)|
  commits = get(a, b)
  cherry = cherry_picked(a, b)
  difference = commits - pull_commits
  puts "#{a}..#{b}: #{difference.count} commits on master, (#{percentage(difference.count, commits.count)}%) #{commits.count} total commits."
  difference = difference - cherry
  puts "Removing cherry-pick commits (#{cherry.count})"
  puts "#{a}..#{b}: #{difference.count} commits on master, (#{percentage(difference.count, commits.count)}%) #{commits.count} total commits."
  puts ""
  #pp difference
end
