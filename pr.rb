#!/usr/bin/env ruby

require "bundler/setup"
require_relative "db"
require "json"
require "pp"

DB.pulls("
  WHERE
  number = ?
", ARGV.first).first.tap do |data|
  pp data
end
