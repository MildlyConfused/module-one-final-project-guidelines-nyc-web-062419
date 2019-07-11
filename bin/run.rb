require_relative "../config/environment"


loc = Location.create(name: "A", address: "Place")


user = Cli.new

user.run


