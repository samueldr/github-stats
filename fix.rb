#!/usr/bin/env ruby

require "bundler/setup"
require_relative "db"

# DB.pulls("
#   WHERE
#   -- ??
#   ORDER BY updated_at ASC
# ").each do |data|
#   #if data[:merge_commit_sha] then
#   #  DB.replace_pull(data)
#   #end
#     pp data
#     exit 1
# end
#pp DB.pull_commits("
#  WHERE
#    raw_body IS NULL
#").count
#
#DB.pull_commits("
#  WHERE
#    raw_body IS NULL
#").each do |data|
#  if data[:commit][:message] then
#    # FIXME
#    #DB.replace_commit(data)
#  end
#end
#

pp DB.issues("LIMIT 1").first
