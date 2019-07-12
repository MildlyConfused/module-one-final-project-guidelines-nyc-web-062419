require_relative "../config/environment"

# hash = {
#   1 => 3,
#   2 => 2,
# }
# overhash = {
#   1 => 7,
# }
# underhash = {
#   1 => 1,
# }

user = Cli.new

Action.cli = user

user.run
