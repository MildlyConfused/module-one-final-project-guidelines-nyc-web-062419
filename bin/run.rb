require_relative "../config/environment"


user = Cli.new

Action.cli = user

user.run
