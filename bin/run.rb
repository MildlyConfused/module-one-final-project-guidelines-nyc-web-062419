require_relative "../config/environment"

user = Cli.new

user.greet

user.get_location

while true
  user.show_actions
end

# binding.pry
