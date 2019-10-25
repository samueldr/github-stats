#!/usr/bin/env ruby

require "csv"
require "bundler/setup"
require_relative "db"

def parse_date(date)
	date.split(" ").first
end

def generate_daily_issue_like(type)
  File.open("stats/#{type}.per-day.csv", "w") do |file|
    puts "Preparing #{type}..."
    fields = [
      :number,
      :created_at,
      :updated_at,
      :closed_at,
      :state,
    ]

    coll = DB.send(type, "ORDER BY updated_at")

    first_date = coll.first[:created_at]
    last_date = coll.last[:created_at]
    last_date = coll.last[:closed_at] if coll.last[:closed_at]

    created = Hash.new { |h, k| h[k] = [] }
    closed = Hash.new { |h, k| h[k] = [] }


    coll.each do |el|
      created_at = parse_date(el[:created_at])
      created[created_at] << el

      if el[:closed_at] then
        closed_at = parse_date(el[:closed_at])
        closed[closed_at] << el
      end
    end

    dates = (created.keys + closed.keys).uniq.sort

    closed_total = 0
    created_total = 0
    file.write CSV.generate_line([:date, :created, :closed, :diff])
    dates.each do |date|
      created_total += created[date].length if created[date]
      closed_total += closed[date].length if closed[date]
      file.write CSV.generate_line([date, created_total, closed_total, created_total-closed_total])
    end

    puts "Done writing #{type}"
  end
end

def generate_bimonthly_for(type)
	puts "Preparing bimonthly #{type}..."
	File.open("stats/#{type}.bimonthly.csv", "w") do |file|
		file.write CSV.generate_line([:date, :created, :closed, :diff])
		# Keeping the last day of every month.
		data = {}
		CSV.foreach("stats/#{type}.per-day.csv", headers: true) do |row|
			

		end
		#file.write CSV.generate_line([date, created_total, closed_total, created_total-closed_total])
		puts "Done writing bimonthly #{type}"
	end
end

`mkdir -p stats`
#generate_daily_issue_like(:issues)
#generate_daily_issue_like(:pulls)

generate_bimonthly_for(:issues)

