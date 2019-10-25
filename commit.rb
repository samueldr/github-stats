#!/usr/bin/env ruby

require "bundler/setup"
require_relative "db"
require "json"
require "pp"

## Matches most package updates.
## This is needed since LIKE isn't powerful enough.
#def is_package_update(data)
#  title = data[:title]
#  title.match(/[0-9.-]+\s*(->|→)\s*[0-9.-]+/)
#end
#
#def has_label(data, label_name)
#  labels = data[:labels].map{|l|l[:name]}
#  labels.find { |name| name == label_name }
#end
#
#def is_wip(data)
#  # By title
#  title = data[:title]
#  return true if title.downcase.match(/^wip[^a-z]|[^a-z]wip$|[\[(]wip[)\]]/)
#  has_label(data, "2.status: work-in-progress")
#end
#
#def is_clean(data)
#  !has_label(data, "2.status: merge conflict")
#end
#
#DB.pulls("
#  WHERE
#    (   title LIKE '%->%'
#    OR  title LIKE '%→%'
#    )
#    AND
#        state = 'open'
#  ORDER BY updated_at ASC
#").each do |data|
#  if is_package_update(data) and !is_wip(data) and is_clean(data) then
#    #marker = if is_clean(data) then " " else "!" end
#    marker = " "
#    puts "%s[%s / %s] #%-6d %s" % [ marker, data[:created_at], data[:updated_at], data[:number], data[:title] ]
#  end
#end

pp DB.pull_commits("LIMIT 1").first
