
class Action

    attr_reader :prompt, :error, :func_array
    attr_accessor :input, :incomplete

    @@general_array = [
        [lambda{|v| v == "!help"},
            lambda{|v| puts "[Gives help]"}],
        [lambda{|v| v == "!exit"},
            lambda{|v| puts "[exits program]"}],
        [lambda{|v| v == "!cancel"},
            lambda{|v| puts "[cancels current]"}]]

    def self.general
        @@general_array
    end

    def initialize(prompt, error, func_array)
        @prompt = prompt
        @error = error
        @input = nil
        @func_array = func_array
        @incomplete = true
    end

    def fire
        while incomplete
            puts self.prompt
            puts "\n"
            self.input = gets.chomp
            puts "\n"
            merged_array = self.func_array + Action.general
            validators = merged_array.collect{|pair| pair[0]}
            validator = validators.find{|val| val.call(self.input)}
            if validator
                self.incomplete = false
                index_lookup = merged_array.index{|pair| pair[0] == validator }
                behavior = merged_array[index_lookup][1]
                behavior.call(self.input)
            else 
                puts self.error
            end
        end
    end
end

