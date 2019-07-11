
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
        lambda{|v| v == "change store"}
        ]

    @@behaviors = [
        lambda{|v| puts "[Help]"},
        lambda{|v| puts "Have a great day!"
                exit},
        lambda{|v|},
        lambda{|v| Action.cli.current_store = nil}
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


        unless complete
            puts self.prompt
            puts "\n"
            self.input = gets.chomp
            puts "\n"
            total_validators = self.validators + Action.validators
            validator_index = total_validators.index{|val| val.call(self.input)}
            
            if validator_index
                self.complete = true
                total_behaviors = self.behaviors + Action.behaviors
                behavior = total_behaviors[validator_index]
                behavior.call(self.input)
            else 
                puts self.error
            end
        end
    end
end

