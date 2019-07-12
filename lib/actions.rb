
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
        lambda{|v| puts "                                                               
                                                               
            ____    ____                                            _      
            `MM'    `MM'                                           dM.     
             MM      MM                                           ,MMb     
             MM      MM    ___    ____    ___   ____              d'YM.    
             MM      MM  6MMMMb   `MM(    )M'  6MMMMb            ,P `Mb    
             MMMMMMMMMM 8M'  `Mb   `Mb    d'  6M'  `Mb           d'  YM.   
             MM      MM     ,oMM    YM.  ,P   MM    MM          ,P   `Mb   
             MM      MM ,6MM9'MM     MM  M    MMMMMMMM          d'    YM.  
             MM      MM MM'   MM     `Mbd'    MM               ,MMMMMMMMb  
             MM      MM MM.  ,MM      YMP     YM    d9         d'      YM. 
            _MM_    _MM_`YMMM9'Yb.     M       YMMMM9        _dM_     _dMM_"
            puts "                                                                                        
            ____                                            ________                          8  
           6MMMMb/                                          `MMMMMMMb.                       (M) 
          8P    YM                              /            MM    `Mb                       (M) 
         6M      Y ___  __   ____      ___     /M            MM     MM    ___    ____    ___ (M) 
         MM        `MM 6MM  6MMMMb   6MMMMb   /MMMMM         MM     MM  6MMMMb   `MM(    )M'  M  
         MM         MM69   6M  `Mb 8M   `Mb   MM             MM     MM 8M'  `Mb   `Mb    d'   M  
         MM     ___ MM'    MM    MM     ,oMM  MM             MM     MM     ,oMM    YM.  ,P    M  
         MM     `M  MM     MMMMMMMM  6MM9 MM  MM             MM     MM ,6MM9'MM     MM  M     8  
         YM      M  MM     MM       MM   MM   MM             MM     MM MM'   MM     `Mbd'        
          8b    d9  MM     YM    d9 MM.  ,MM   YM.  ,        MM    .M9 MM.  ,MM      YMP     68b 
           YMMMM9  _MM_     YMMMM9  `YMMM9'Yb.  YMMM9       _MMMMMMM9' `YMMM9'Yb.     M      Y89 
                                                                                     d'          
                                                                                 (8),P           
                                                                                  YMM            "
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

