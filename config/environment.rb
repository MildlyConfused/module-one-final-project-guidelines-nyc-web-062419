require "bundler"
require "dotenv/load"
require "mailgun-ruby"
require "date"
Bundler.require

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "db/development.db")
ActiveRecord::Base.logger = nil
require_all "lib"
