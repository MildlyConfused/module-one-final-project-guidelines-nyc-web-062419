class Cli

  attr_accessor :current_store, :running

  def initialize
    @current_store = nil
    @running = true
  end

  def act(prompt, error, func_array)
    Action.new(prompt, error, func_array).fire
  end

=begin

How to build an action method

  def <Method Name>(<Arguments>)
    self.act(
      <Initial Prompt>,
      <Non-Validation Error>,
      [[lambda{|v|<Validation Condition>},
        lambda{|v|<Behavior for that Condition>}],
      <As many more such entries as needed>])
  end

=end

  def run
    puts "\n"
    puts "Welcome Employee!"
    puts "\n"
    puts "(You can always enter '!help' to see a list of possible commands.)"
    puts "(You can always enter '!exit' to exit the program.)"
    while running do
      puts "\n"
      puts "_____________________________"
      puts "\n"
      puts "\n"
      if !self.current_store
        get_location
      else
        location_actions
      end
    end
  end



  def select_stock_to_buy
    self.act(
      "Please enter the fullname of the desired SKU:",
      "Sorry, there is no record of that SKU.",
      [[lambda{|v| Sku.find_by_fullname(v)},
        lambda{|v| choose_quantity_of_stock_to_buy(v)}]])
  end




  

 

  
  def location_actions
    location_actions_pairs = [
      # [<Name_of_action_for_user> , <lambda package of corresponding function>],
      ["Buy stock for store", lambda{|v| select_stock_to_buy}],
      ["Report lost, stolen, or damaged goods", lambda{|v| report_lsd_items}],
      ["Update price of item for store", lambda{|v| update_price_of_some_item}],
      ["Find other stores with item", lambda{|v| choose_item_to_find}],
      ["Request item from another store", lambda{|v| request_goods_from_other_store}],
      ["View full catalog of sallable goods", lambda{|v| view_catalog}],
      ["Check stock of item", lambda{|v| check_stock_count}],
      ["View store inventory", lambda{|v| display_inventory}]]



    self.act(
      lambda{init_string_array = ["The current store is #{current_store.name} located at #{current_store.address}.\nHere are your possible store actions:"]
      location_actions_pairs.each_with_index do |pair, i|
        init_string_array.push("  #{i + 1}. #{pair[0]}")
      end
      init_string_array.join("\n")}.call,
      "Sorry, that's not a number that corresponds to an action.",
      lambda{final = []
      location_actions_pairs.each_with_index do |pair, i|
        final.push([lambda{|v| v == "#{i + 1}"}, pair[1]])
      end
      final}.call)
  end 
  





      
        
        
  




  

  





  def get_location
    self.act(
      "Please enter the address of your store location:",
      "Store not found. Please enter a valid address.",
      [[lambda{|v| Location.find_location_by_address(v)},
        lambda{|v| self.current_store = Location.find_location_by_address(v)}]])
      
  end



  def select_stock_to_buy
    self.act(
      "Please enter the fullname of the desired SKU:",
      "Sorry, there is no record of that SKU.",
      [[lambda{|v| Sku.find_by_fullname(v)},
        lambda{|v| choose_quantity_of_stock_to_buy(Sku.find_by_fullname(v))}]])
        
  end

  def choose_quantity_of_stock_to_buy(sku)
    self.act(
      "Please enter the quantity you want to purchase:",
      "Sorry, that's not a quantity.",
      [[lambda{|v| v.to_i > 0},
        lambda{|v| self.current_store.get_stock(sku, v.to_i, nil)
                  puts "Thank you for your purchase of #{v} #{sku.fullname}(s)"
                  set_price_of_item(sku)}]])
  end

  def update_price_of_some_item
    self.act(
      "Please enter the fullname of the item to update:",
      "Sorry, there's none of that item at this store.",
      [[lambda{|v| self.current_store.stock.select{|stock_item| stock_item.sku == Sku.find_by_fullname(v)}.length > 0},
        lambda{|v| set_price_of_item(Sku.find_by_fullname(v))}]])
  end

  def set_price_of_item(sku)
    self.act(
      "Please enter the ammount in dollars you will charge for #{sku.fullname}(s)",
      "Sorry, that's not a dollar ammount.",
      [[lambda{|v|if v[0] == "$"
                    s = v[1...v.length]
                  else
                    s = v
                  end
                  ("0"+ s).to_f > 0},
        lambda{|v|if v[0] == "$"
                    s = v[1...v.length]
                  else
                    s = v
                  end
                  s = ("0" + s).to_f.round(2)
                  self.current_store.set_price_for_sku_here(sku, s)
                  puts "OK, you now charge $#{s} for #{sku.fullname}(s)."}]])
  end


  def check_stock_count
    self.act(
      "Please enter the fullname of the SKU you want to check:",
      "Sorry, there is no record of that SKU.",
      [[lambda{|v|Sku.find_by_fullname(v)},
        lambda{|v|sku = Sku.find_by_fullname(v)
                  puts "There are #{self.current_store.stock_count(sku)} #{sku.fullname}(s) in stock."}]])
  end

  def report_lsd_items
    self.act(
      "Please enter the fullname of the item:",
      "Sorry, there is no record of that SKU.",
      [[lambda{|v|Sku.find_by_fullname(v)},
        lambda{|v|remove_lsd_item(Sku.find_by_fullname(v))}]])
  end

  def remove_lsd_item(sku)
    self.act(
      "Please enter the quantity of #{} that are lost, damaged, or stolen:",
      "Sorry, that's not a quantity.",
      [[lambda{|v|v.to_i > 0},
        lambda{|v|self.current_store.report_lost_or_stolen(sku, v.to_i)
                  puts "Thank you, we've updated inventory."}]])

  end



  def choose_item_to_find
    self.act(
      "Please enter the fullname of the SKU you want to find:",
      "Sorry, there is no record of that SKU.",
      [[lambda{|v|Sku.find_by_fullname(v)},
        lambda{|v|find_item_elsewhere(Sku.find_by_fullname(v))}]])
  end
  
  def find_item_elsewhere(sku)
    self.act(
      "Please enter the quantity of #{sku.fullname}(s) that you want to find:",
      "Sorry, that's not a quantity.",
      [[lambda{|v|v.to_i > 0},
        lambda{|v|other_locations = self.current_store.find_elsewhere(sku, v.to_i)
                  if other_locations.length != 0
                    puts "Here are the locations where you can find this item:"
                    other_locations.each.with_index do |location, i|
                      puts "#{i+1}. #{location.name} at #{location.address} has #{location.stock_count(sku)}."
                    end
                  else
                    puts "Sorry, all other stores are out of stock."
                  end}]])
  end

  def request_goods_from_other_store
    self.act(
      "Please enter the fullname of the SKU you want to request:",
      "Sorry, there is no record of that SKU.",
      [[lambda{|v|Sku.find_by_fullname(v)},
        lambda{|v|request_this_good_from_other_store(Sku.find_by_fullname(v))}]])
  end

  def request_this_good_from_other_store(sku)
    self.act(
      "Please enter the quantity of #{sku.fullname}(s) that you want to request:",
      "Sorry, that's not a quantity.",
      [[lambda{|v|v.to_i > 0},
        lambda{|v|request_number_of_good_from_other_store(sku, v.to_i)}]])
  end

  def request_number_of_good_from_other_store(sku, quantity)
    self.act(
      "Please enter the address of the store you want the goods from:",
      "Sorry, no location with that address has those goods.",
      [[lambda{|v|location = Location.find_location_by_address(v)
                  if location
                    location.in_stock?(sku, quantity)
                  else
                    false
                  end},
        lambda{|v|location = Location.find_location_by_address(v)
                  self.current_store.request_stock_from(sku, quantity, location)}]])
  end

  
  def view_catalog
    puts "Your store may order and sell the following items:"
    Sku.all.each.with_index {|sku, i| puts "#{i + 1}. #{sku.fullname}" }
  end

  def display_inventory
    to_print = Sku.all.each_with_object({}) do |sku, hash|
      if current_store.in_stock?(sku, 1)
        hash[sku.fullname] = current_store.stock_count(sku)
      end
    end
    if to_print.keys.count > 0
      to_print.each { |key, value| puts "You have #{value.to_s} of #{key}." }
    else
      puts "You have no rights to own a store"
    end
  end

  



end


