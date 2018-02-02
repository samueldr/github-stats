#!/usr/bin/env nix-shell
#!ruby # Hack for ruby parsing shebangs.
#!nix-shell -p ruby -i ruby

require "pp"
require "json"

def parse_date(date)
	date.split(" ").first
end

pulls = JSON.parse(File.read("pulls.json"))

first_date = pulls.first["created_at"]
last_date = pulls.last["created_at"]
last_date = pulls.last["closed_at"] if pulls.last["closed_at"]


created = {}
closed = {}

pulls.each do |pull|
	created_at = parse_date(pull["created_at"])
	created[created_at] ||= []
	created[created_at] << pull

	if pull["closed_at"] then
		closed_at = parse_date(pull["closed_at"])
		closed[closed_at] ||= []
		closed[closed_at] << pull
	end
end

dates = (created.keys + closed.keys).uniq.sort

closed_total = 0
created_total = 0

puts "date,created,closed,diff"
dates.each do |date|
	created_total += created[date].length if created[date]
	closed_total += closed[date].length if closed[date]
	puts "#{date},#{created_total},#{closed_total},#{created_total-closed_total}"
end
