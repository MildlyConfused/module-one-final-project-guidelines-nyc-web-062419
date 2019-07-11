require_relative "../config/environment"

loc = Location.create(name: "A", address: "Place")


user = Cli.new

Action.cli = user

user.run
