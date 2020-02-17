#!/usr/bin/env ruby

require "bundler/setup"
require_relative "db"

require "net/http"
require "uri"
require "shellwords"

def fetch(uri_str, limit = 10)
  # You should choose better exception.
  raise ArgumentError, "HTTP redirect too deep" if limit == 0

  url = URI.parse(uri_str)
  req = Net::HTTP::Get.new(url.path, { "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64; rv:72.0) Gecko/20100101 Firefox/72.0" })
  response = Net::HTTP.start(url.host, url.port, use_ssl: true) { |http| http.request(req) }
  case response
  when Net::HTTPSuccess     then response
  when Net::HTTPRedirection then fetch(response["location"], limit - 1)
  else
    response.error!
  end
end


def get_diff(commitish)
  sleep 0.01
  $stderr.puts "Fetching #{commitish} from github"
  res = fetch("https://github.com/NixOS/nixpkgs/commit/#{commitish}.patch")
  diff = res.body

  preamble = diff[0..4]
  unless preamble == "From " or diff == ""
    raise "Diff might be broken, '#{preamble}' should be 'From '"
  end

  diff
end

res = $db.execute("SELECT COUNT(sha) FROM pull_commits WHERE diff IS NULL")
count = res.first.first

$stderr.puts "Working with #{count} commits..."

def git(*cmd)
  Dir.chdir(ENV["REPO_PATH"]) do
    `git #{cmd.shelljoin}`
  end
end

git("fetch", "--all")

$db.execute("SELECT sha FROM pull_commits WHERE diff IS NULL").each_with_index do |sha, i|
  $stderr.puts "#{i}/#{count}..."
  sha = sha.first

  diff = git("show", sha)
  begin
    diff = get_diff(sha) if diff == ""
  rescue Net::HTTPClientException => e
    $stderr.puts " ... Skipping what is likely a too big commit... 🤷"
    DB.update_diff(sha, "$ERROR:#{e.response.code}$")
    next
  end

  DB.update_diff(sha, diff)
end
