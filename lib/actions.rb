
class Action

    attr_reader :prompt, :error, :validators, :behaviors
    attr_accessor :input, :complete

    @@cli = nil

    def self.cli
        @@cli
    end

    def self.cli=(input)
        @@cli = input
    end

    
    

    @@validators = [
        lambda{|v| v == "help"},
        lambda{|v| v == "exit"},
        lambda{|v| v == "cancel"},
        lambda{|v| v == "change"}
        ]

    @@behaviors = [
        lambda{|v|
            puts Action.cli.display_as_numbered_list(
                header: "You may use the following commands at any time:",
                strings: ["'help'\tDisplays this list of global options.",
                        "'exit'\tExits the program.",
                        "'cancel'\tCancles the current request and returns to menu.",
                        "'change'\tChanges the current store.\n"])
            puts " \n(press enter to continue)"
            gets},
        lambda{|v| puts "Have a great day!\n \n "
                exit},
        lambda{|v| v.complete = true},
        lambda{|v| v.complete = true
                   Action.cli.current_store = nil}
        ]

    def self.validators
        @@validators
    end

    def self.behaviors
        @@behaviors
    end


    def initialize(prompt:, error:, validators:, behaviors:)
        @prompt = prompt
        @error = error
        @validators = validators
        @behaviors = behaviors
        @input = nil
        @complete = false


        until complete
            puts self.prompt
            puts "\n"
            self.input = gets.chomp
            puts "\n"

            local_validator_index = self.validators.index{|val| val.call(self.input)}
            global_validator_index = Action.validators.index{|val| val.call(self.input)}

            
            
            if local_validator_index
                self.complete = true
                behavior = self.behaviors[local_validator_index]
                behavior.call(self.input)
            elsif global_validator_index
                behavior = Action.behaviors[global_validator_index]
                behavior.call(self)
            else 
                puts self.error
            end
        end
    end
end

