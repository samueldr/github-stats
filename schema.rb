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

require_relative "db"

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
