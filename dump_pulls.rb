#!/usr/bin/env ruby

require "csv"
require "bundler/setup"
require_relative "db"

def parse_date(date)
	date.split(" ").first
end

def generate_pulls()
    $db.execute("SELECT data FROM pulls #{where}", *params).each do |(data)|
      el = JSON.parse(data, symbolize_names: true)
	  filename = "pulls/#{el[:number]}.json"
	  contents = el.to_json
	  File.write(filename, contents)
    end
	#DB.pulls().each do |el|
	#end
end

`mkdir -p pulls`
generate_pulls()
