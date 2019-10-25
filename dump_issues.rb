#!/usr/bin/env ruby

require "csv"
require "bundler/setup"
require_relative "db"

def parse_date(date)
	date.split(" ").first
end

def generate_issues()
	DB.issues().each do |el|
		filename = "issues/#{el[:number]}.json"
		contents = el.to_json
		File.write(filename, contents)
	end
end

`mkdir -p issues`
generate_issues()
