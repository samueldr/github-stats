#!/usr/bin/env ruby

require "bundler/setup"
require_relative "db"
require "pp"

filename = ARGV.first

pull_commits = $db.execute("SELECT sha FROM pull_commits;").map { |row| row.first }

all_commits = File.read(filename).split("\n")

difference = all_commits - pull_commits

#pp all_commits.count
#pp difference.count

puts difference.join("\n")
