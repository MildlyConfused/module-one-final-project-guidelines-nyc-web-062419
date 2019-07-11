class Cli

  attr_accessor :current_store, :running

  def initialize
    @current_store = nil
    @running = true
  end

  def does(prompt:, error:, validators:, behaviors:)
    Action.new(
      prompt: prompt,
      error: error,
      validators: validators, 
      behaviors: behaviors
    )
  end

=begin

    Any feedback loop with the user involves making an Action

    Any Action init has the form:
    
    does(
      prompt:,
      error:,
      validators: [], 
      behaviors: []
      )

    Validators and Beaviors are arrays.
    They contain 1-argument lambdas.
    The correspond to each other by possition.
    So, they must have an equal number.

=end

  def display_as_numbered_list(header:, strings:)
    string_array = [header + "\n"]
    strings.each_with_index do |string, i|
      string_array.push("  #{i + 1}. " + string)
    end
    string_array.join("\n")
  end


  def choose_by_number(header:, cbn_prompts:, cbn_behaviors:)
    # Makes an action where options are listed by number, and one is chosen by number.
    # Prompts and behaviors should correspond
    validator_array = []
    cbn_behaviors.each_index do |i|
      validator_array.push(lambda{|v| v == "#{i + 1}"})
    end
    does(
      prompt: display_as_numbered_list(header: header, strings: cbn_prompts),
      error: "Sorry, that's not a number that corresponds to an action.",
      validators: validator_array, 
      behaviors: cbn_behaviors
      )
  end

  def run
    puts "\n"
    puts "Welcome Employee!"
    puts "\n"
    puts "(You can always enter 'help' to see a list of possible commands.)"
    puts "(You can always enter 'exit' to exit the program.)"
    while running do
      puts "\n"
      if !self.current_store
        get_location
      else
        location_actions
      end
      puts "\n"
      puts "(press enter to continue)"
      cont = gets
    end
  end


  def get_location
    does(
      prompt: "Please enter the address of your store location:",
      error: "Store not found. Please enter a valid address.",
      validators: [lambda{|v| Location.find_location_by_address(v)}], 
      behaviors: [lambda{|v| self.current_store = Location.find_location_by_address(v)}]
      )  
  end

  

  




  
  def location_actions
    location_action_pairs = [
      # [<Name_of_action_for_user> , <lambda package of corresponding function>],
      ["Buy stock for store", lambda{|v| select_stock_to_buy}],
      ["Report lost, stolen, or damaged goods", lambda{|v| report_lsd_items}],
      ["Update price of item for store", lambda{|v| update_price_of_some_item}],
      ["Find other stores with item", lambda{|v| choose_item_to_find}],
      ["Request item from another store", lambda{|v| request_goods_from_other_store}],
      ["View full catalog of sellable goods", lambda{|v| view_catalog}],
      ["Check stock of item", lambda{|v| check_stock_count}],
      ["View store inventory", lambda{|v| display_inventory}]]

    location_prompts = location_action_pairs.collect{|pair| pair[0]}

    location_behaviors = location_action_pairs.collect{|pair| pair[1]}
    choose_by_number(header: "Please choose an action for #{current_store.name}, located at #{current_store.address}:", 
      cbn_prompts: location_prompts, cbn_behaviors: location_behaviors)

  end
    


    
  



  def select_stock_to_buy
    does(
      prompt: "Please enter the fullname of the desired SKU:",
      error: "Sorry, there is no record of that SKU.",
      validators: [lambda{|v| Sku.find_by_fullname(v)}], 
      behaviors: [lambda{|v| choose_quantity_of_stock_to_buy(Sku.find_by_fullname(v))}]
      )
  end


  def choose_quantity_of_stock_to_buy(sku)
    does(
      prompt: "Please enter the quantity you want to purchase:",
      error: "Sorry, that's not a quantity.",
      validators: [lambda{|v| v.to_i > 0}], 
      behaviors: [lambda{|v| self.current_store.get_stock(sku, v.to_i, nil)
        puts "Thank you for your purchase of #{v} #{sku.fullname}(s)"
        set_price_of_item(sku)}]
      )
  end

  def update_price_of_some_item
    does(
      prompt: "Please enter the fullname of the item to update:",
      error: "Sorry, there's none of that item at this store.",
      validators: [lambda{|v| self.current_store.stock.select{|stock_item| stock_item.sku == Sku.find_by_fullname(v)}.length > 0}], 
      behaviors: [lambda{|v| set_price_of_item(Sku.find_by_fullname(v))}]
      )
  end

  def set_price_of_item(sku)
    does(
      prompt: "Please enter the ammount in dollars you will charge for #{sku.fullname}(s)",
      error: "Sorry, that's not a dollar ammount.",
      validators: [lambda{|v|if v[0] == "$"
                    s = v[1...v.length]
                  else
                    s = v
                  end
                  ("0"+ s).to_f > 0}], 
      behaviors: [lambda{|v|if v[0] == "$"
                    s = v[1...v.length]
                  else
                    s = v
                  end
                  s = ("0" + s).to_f.round(2)
                  self.current_store.set_price_for_sku_here(sku, s)
                  puts "OK, you now charge $#{s} for #{sku.fullname}(s)."}]
    )
  end


  def check_stock_count
    does(
      prompt: "Please enter the fullname of the SKU you want to check:",
      error: "Sorry, there is no record of that SKU.",
      validators: [lambda{|v|Sku.find_by_fullname(v)}], 
      behaviors: [lambda{|v|sku = Sku.find_by_fullname(v)
                  puts "There are #{self.current_store.stock_count(sku)} #{sku.fullname}(s) in stock."}]
      )
  end

  def report_lsd_items
    does(
      prompt: "Please enter the fullname of the item:",
      error: "Sorry, there is no record of that SKU.",
      validators: [lambda{|v|Sku.find_by_fullname(v)}], 
      behaviors: [lambda{|v|remove_lsd_item(Sku.find_by_fullname(v))}]
      )
  end

  def remove_lsd_item(sku)
    does(
      prompt: "Please enter the quantity of #{sku.fullname} that are lost, damaged, or stolen:",
      error: "Sorry, that's not a quantity.",
      validators: [lambda{|v|v.to_i > 0}], 
      behaviors: [lambda{|v|self.current_store.report_lost_or_stolen(sku, v.to_i)
                  puts "Thank you, we've updated inventory."}]
      )
  end



  def choose_item_to_find
    does(
      prompt: "Please enter the fullname of the SKU you want to find:",
      error: "Sorry, there is no record of that SKU.",
      validators: [lambda{|v|Sku.find_by_fullname(v)}], 
      behaviors: [lambda{|v|find_item_elsewhere(Sku.find_by_fullname(v))}]
      )
  end
  
  def find_item_elsewhere(sku)
    does(
      prompt: "Please enter the quantity of #{sku.fullname}(s) that you want to find:",
      error: "Sorry, that's not a quantity.",
      validators: [lambda{|v|v.to_i > 0}], 
      behaviors: [lambda{|v|other_locations = self.current_store.find_elsewhere(sku, v.to_i)
                  if other_locations.length != 0
                    display_strings = other_locations.collect{|location| "#{location.name} at #{location.address} has #{location.stock_count(sku)}."}
                    puts display_as_numbered_list(header: "Here are the locations where you can find this item:", strings:display_strings)
                  else
                    puts "Sorry, all other stores are out of stock."
                  end}]
      )
  end

  def request_goods_from_other_store
    does(
      prompt: "Please enter the fullname of the SKU you want to request:",
      error: "Sorry, there is no record of that SKU.",
      validators: [lambda{|v|Sku.find_by_fullname(v)}], 
      behaviors: [lambda{|v|request_this_good_from_other_store(Sku.find_by_fullname(v))}]
      )
  end

  def request_this_good_from_other_store(sku)
    does(
      prompt: "Please enter the quantity of #{sku.fullname}(s) that you want to request:",
      error: "Sorry, that's not a quantity.",
      validators: [lambda{|v|v.to_i > 0}], 
      behaviors: [lambda{|v|request_number_of_good_from_other_store(sku, v.to_i)}]
      )
  end

  def request_number_of_good_from_other_store(sku, quantity)
    does(
      prompt: "Please enter the address of the store you want the goods from:",
      error: "Sorry, no location with that address has those goods.",
      validators: [lambda{|v|location = Location.find_location_by_address(v)
                  if location
                    location.in_stock?(sku, quantity)
                  else
                    false
                  end}], 
      behaviors: [lambda{|v|location = Location.find_location_by_address(v)
                  self.current_store.request_stock_from(sku, quantity, location)
                  puts "The requested stock has been transferred."}]
      )
  end

  
  def view_catalog
    puts display_as_numbered_list(
      header: "Your store may order and sell the following items:",
      strings: Sku.all.collect {|sku| "#{sku.fullname}"}
      )
  end

  def display_inventory
    to_print = Sku.all.each_with_object({}) do |sku, hash|
      if current_store.in_stock?(sku, 1)
        hash[sku.fullname] = current_store.stock_count(sku)
      end
    end
    if to_print.keys.count > 0
      puts display_as_numbered_list(
        header:  "Your store has the following inventory:",
        strings: to_print.collect{ |sku_name, quantity| "#{sku_name} -- #{quantity.to_s}" },
      )
    else
      puts "You have no rights to own a store"
    end
  end
end