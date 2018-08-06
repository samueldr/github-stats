require "sqlite3"
require "json"
$db = SQLite3::Database.new "cache.db"

module DB
  extend self

  def _insert(table, data, *fields)
    values = fields.map do |field|
      data[field]
    end
    data = JSON.generate(data)
    $db.execute(
      "REPLACE INTO #{table} (#{fields.concat([:data]).join(", ")}) VALUES(#{fields.map{"?"}.join(", ")})",
      *values,
      data
    )
  end

  # Insert or replace PR
  def replace_pull(data)
    data = data.to_hash
    data[:author_id] = data[:user][:id]
    data[:merger_id] = data[:merged_by][:id] if data[:merged_by]
    DB.replace_user(data[:user])
    DB.replace_user(data[:merged_by]) if data[:merged_by]
    _insert(:pulls, data, :id, :number, :state, :author_id, :merger_id)
  end

  # Insert or replace user
  def replace_user(data)
    data = data.to_hash
    return unless data[:login] # It seems it's possible to have a login-less user :/ FIXME
    _insert(:users, data, :id, :login, :avatar_url)
  end

  # Insert or replace commit
  def replace_commit(pull_number, data)
    replace_user(data[:author]) if data[:author]
    replace_user(data[:committer]) if data[:committer]
    data = data.to_hash
    data[:pull_number] = pull_number
    data[:author_id] = data[:author][:id] if data[:author]
    data[:committer_id] = data[:committer][:id] if data[:committer]
    _insert(:pull_commits, data, :pull_number, :sha, :author_id, :committer_id,)
  end

  # Re-hydrates all the pull requests.
  # TODO : parameters
  def pulls(where = "")
    $db.execute("SELECT data FROM pulls #{where}").map do |(data)|
      JSON.parse(data, symbolize_names: true)
    end
  end
end
