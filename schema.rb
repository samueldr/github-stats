#!/usr/bin/env ruby

# Creates the database schema.
#
# DO NOTE:
#
# This database acts as *a cache*.
#
# Thus the migration scheme right now is delete and re-create.
#
# thankyouverymuch.

require "bundler/setup"
require_relative "db"
require "pp"

#
# Schema migration idea:
#
# Some operations will require a dump-out-dump-in, such as renaming columns.
# For those, a function will be written to automate it.
#
# Until then:
#
# Add a migrations table, with `| name | date |` fields.
#
# Apply each "migration scripts" sequentially.
#
# Assume missing table if from -1 to 0.
#
# TODO : find a supported wrapper with proper migrations scheme?
#

with_migrations =
  $db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='migrations'")
    .count > 0

unless with_migrations then
  # Seed the initial structure if needed
  create_tables =
    $db.execute("SELECT name FROM sqlite_master WHERE type='table'")
      .count != 3

  # Initial schema.
  if create_tables then
    $db.execute_batch <<-SQL
      create table pulls (
        id INTEGER NOT NULL PRIMARY KEY,      -- github ID, not the PR #
        number INTEGER NOT NULL,              -- the PR #
        state TEXT NOT NULL,                  -- open, closed, merged
        author_id INTEGER NOT NULL,           -- github ID of who opened it
        merger_id INTEGER,                    -- github ID of who merged it
        data TEXT NOT NULL                    -- json dump from API; may include foreign fields.
      );

      create table users (
        id INTEGER NOT NULL PRIMARY KEY,      -- github ID
        login TEXT NOT NULL,                  -- @samueldr
        avatar_url TEXT NOT NULL,             -- hey, fun!
        data TEXT NOT NULL                    -- json dump from API; may include foreign fields.
      );

      -- From a pull request, _links.commits.href
      create table pull_commits (
        pull_number INTEGER NOT NULL,         -- let's prefer using PR number
        sha TEXT NOT NULL PRIMARY KEY,        -- commit ID
        author_id INTEGER,                    -- users.id of author
        committer_id INTEGER,                 -- users.id of committer
        data TEXT NOT NULL                    -- json dump from API; may include foreign fields.
      );
    SQL
  end

  # Adds `migrations`
  $db.execute_batch <<-SQL
    create table migrations (
      name TEXT NOT NULL,
      date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  SQL
end

def migration(name, sql)
  applied_migrations = $db.execute("SELECT name, date FROM migrations").to_h
  return if applied_migrations[name.to_s]

  begin
    puts "Doing migration #{name}"

    $db.transaction
    $db.execute("INSERT INTO migrations (name) VALUES(?)", name)
    $db.execute_batch(sql)
    yield if block_given?
    $db.commit

    puts "Finished migration #{name}"
  rescue Exception => e 
    puts "Exception occurred"
    puts e
    $db.rollback
  end
end

migration("2018-08-05-add_merge_commit_sha", "
  ALTER TABLE pulls
  ADD COLUMN merge_commit_sha TEXT
  ;
") do
  $db.execute("SELECT id, data FROM pulls") do |id, data|
    puts " Migrating record #{id}"
    pull = JSON.parse(data, symbolize_names: true)
    $db.execute("UPDATE pulls SET merge_commit_sha = ? WHERE id = ?", pull[:merge_commit_sha], id)
  end
end

migration("2018-08-05-pull_commits_add_raw_body", "
  ALTER TABLE pull_commits
  ADD COLUMN raw_body TEXT
  ;
") do
  $db.execute("SELECT sha, data FROM pull_commits") do |sha, data|
    puts " Migrating record #{sha}"
    pull = JSON.parse(data, symbolize_names: true)
    $db.execute("UPDATE pull_commits SET raw_body = ? WHERE sha = ?", pull[:commit][:message], sha)
  end
end

migration("2018-08-05-pull_commits_add_raw_body_index", "
  CREATE INDEX pull_commits_raw_body
  ON pull_commits (raw_body)
  ;
")
