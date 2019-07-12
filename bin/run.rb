require_relative "../config/environment"

loc = Location.find_or_create_by(name: "A", address: "Place")

hash = {
  1 => 3,
  2 => 2,
}

binding.pry
# overhash = {
#   1 => 7,
# }
# underhash = {
#   1 => 1,
# }

user = Cli.new

Action.cli = user

user.run
