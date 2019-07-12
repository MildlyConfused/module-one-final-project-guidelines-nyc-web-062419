class Cli
  attr_accessor :current_store, :running, :data_store

  def initialize
    @current_store = nil
    @running = true
    @data_store = nil
  end

=begin

    Any feedback loop with the user involves making an Action

    Any Action init has the form:
    
    Action.new(
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

  # Helper Methods

  def display_as_numbered_list(header:, strings:)
    string_array = [header + "\n"]
    strings.each_with_index do |string, i|
      string_array.push("  #{i + 1}. " + string + "\n")
    end
    string_array.join("\n")
  end

  def choose_by_number(header:, cbn_prompts:, cbn_behaviors:)
    # Makes an action where options are listed by number, and one is chosen by number.
    # Prompts and behaviors should correspond
    validator_array = []
    cbn_behaviors.each_index do |i|
      validator_array.push(lambda { |v| v == "#{i + 1}" })
    end
    Action.new(
      prompt: display_as_numbered_list(header: header, strings: cbn_prompts),
      error: "Sorry, that's not a number that corresponds to an action.",
      validators: validator_array,
      behaviors: cbn_behaviors,
    )
  end

  # There's an 'infinite' value, so that you can order as much as you like. Handled with a conditional.

  def get_sku_quantity_hash_from_user(header_1:, header_2:, display_hash:, output_hash:)
    prompts = []
    behaviors = []

    display_hash.each do |sku_id, quantity|
      # Builds the prompts
      quantity_string = ""
      if quantity != "infinite"
        quantity_string = "(#{quantity} available)"
      end
      full_prompt = Sku.find(sku_id).fullname + quantity_string
      prompts.push(full_prompt)
      # Builds the behaviors
      behavior = lambda { |v|
        get_number_for_hash(
          header_1: header_1,
          header_2: header_2,
          display_hash: display_hash,
          output_hash: output_hash,
          chosen_sku_id: sku_id,
          max_number: quantity,
        )
      }
      behaviors.push(behavior)
    end
    choose_by_number(header: header_1,
                     cbn_prompts: prompts,
                     cbn_behaviors: behaviors)
  end

  def get_number_for_hash(header_1:, header_2:, display_hash:, output_hash:, chosen_sku_id:, max_number:)
    Action.new(
      prompt: header_2,
      error: "Sorry, that's not an available quantity.",
      validators: [lambda { |v| v == "0" || (max_number == "infinite" && v.to_i > 0) || (v.to_i > 0 && v.to_i <= max_number.to_i) }],
      behaviors: [lambda { |v|
        user_number = v.to_i
        # Reduces display hash at chosen_sku_id by an ammount given.
        if display_hash[chosen_sku_id] == "infinite"
          display_hash[chosen_sku_id] = "infinite"
        elsif display_hash[chosen_sku_id] == user_number
          display_hash.delete(chosen_sku_id)
        else
          display_hash[chosen_sku_id] -= user_number
        end
        # Increases output hash at chosen_sku_id by an ammount given.
        if output_hash.key?(chosen_sku_id)
          output_hash[chosen_sku_id] += user_number
        else
          output_hash[chosen_sku_id] = user_number
        end
        confirm_hash(header_1: header_1, header_2: header_2, display_hash: display_hash, output_hash: output_hash)
      }],
    )
  end

  def confirm_hash(header_1:, header_2:, display_hash:, output_hash:)
    prompts = []
    output_hash.each do |sku_id, quantity|
      quantity_string = "\t(#{quantity} chosen)"
      full_prompt = Sku.find(sku_id).fullname + quantity_string
      prompts.push(full_prompt)
    end

    Action.new(
      prompt: display_as_numbered_list(header: "\nHere's what you've chosen so far:", strings: prompts) + "\n \nWould you like to add more items?\n(please type 'yes' or 'no')",
      error: "Sorry, you can only chooose 'yes' or 'no'",
      validators: [lambda { |v| v == "yes" },
                   lambda { |v| v == "no" }],
      behaviors: [lambda { |v|
        get_sku_quantity_hash_from_user(
          header_1: header_1, header_2: header_2, display_hash: display_hash, output_hash: output_hash,
        )
      },
                  lambda { |v|
        puts "Ok, we'll process your request!"
        self.data_store = output_hash
      }],
    )
  end

  # The Program's Main Loop

  def run
    system("clear")
    puts "                                                              
                                                              
MM       ___       ___                   ____              MM 
MM       `MMb     dMM'                   `MM'              MM 
MM        MMM.   ,PMM                     MM   /           MM 
MM        M`Mb   d'MM ___  __     __      MM  /M           MM 
MM        M YM. ,P MM `MM 6MMb   6MMbMMM  MM /MMMMM        MM 
MM        M `Mb d' MM  MMM9 `Mb 6M'`Mb    MM  MM           MM 
MM        M  YM.P  MM  MM'   MM MM  MM    MM  MM           MM 
MM        M  `Mb'  MM  MM    MM YM.,M9    MM  MM           MM 
MM        M   YP   MM  MM    MM  YMM9     MM  MM           MM 
MM        M   `'   MM  MM    MM (M        MM  YM.  ,       MM 
MM       _M_      _MM__MM_  _MM_ YMMMMb. _MM_  YMMM9       MM 
MM                              6M    Yb                   MM 
MM                              YM.   d9                   MM 
MM                               YMMMM9                    MM 
                                                              
                                                              "

    puts "Welcome Employee!"
    puts "\n"
    puts "(You can always enter 'help' to see a list of possible commands.)"
    puts "(You can always enter 'exit' to exit the program.)"
    while running
      puts "\n"
      if !self.current_store
        get_location
      else
        location_actions
      end
      puts "\n"
      puts "(press enter to continue)"
      cont = gets
      system("clear")
    end
  end

  # The Large Sub-Loop for when a store is selected

  def location_actions
    location_action_pairs = [
      # [<Name_of_action_for_user> , <lambda package of corresponding function>],
      ["Buy stock for store (by name)", lambda { |v| select_stock_to_buy }],
      ["Buy stock for store (by catalog)", lambda { |v| purchase_stock_by_hash }],
      ["Report lost, stolen, or damaged goods", lambda { |v| report_lsd_items }],
      ["Update price of item for store", lambda { |v| update_price_of_some_item }],
      ["Find other stores with item", lambda { |v| choose_item_to_find }],
      ["Request item from another store", lambda { |v| request_goods_from_other_store }],
      ["View full catalog of sellable goods", lambda { |v| view_catalog }],
      ["Check stock of item", lambda { |v| check_stock_count }],
      ["View store inventory", lambda { |v| display_inventory }],
      ["Process a customer's purchase", lambda { |v| process_user_purchase }],
      ["Process a customer's return", lambda { |v| verify_return_id }],
    ]

    location_prompts = location_action_pairs.collect { |pair| pair[0] }

    location_behaviors = location_action_pairs.collect { |pair| pair[1] }
    choose_by_number(header: "Please choose an action for #{current_store.name}, located at #{current_store.address}:",
                     cbn_prompts: location_prompts, cbn_behaviors: location_behaviors)
  end

  # Specific Actions

  def get_location
    name_address_prompts = Location.all.collect { |loc| "#{loc.name} at #{loc.address}" }
    set_store_behaviors = Location.all.collect { |loc| lambda { |v| self.current_store = loc } }

    choose_by_number(header: "Please choose your store and address:",
                     cbn_prompts: name_address_prompts,
                     cbn_behaviors: set_store_behaviors)
  end

  def purchase_stock_by_hash
    sku_hash = Sku.all.each_with_object({}) { |sku, hash| hash[sku.id] = "infinite" }

    get_sku_quantity_hash_from_user(header_1: "Please enter the line number of the product you'd like to order:",
                                    header_2: "Please enter the quantity of that product you'd like to order:",
                                    display_hash: sku_hash,
                                    output_hash: {})

    if self.data_store != nil
      self.current_store.get_stock_using_hash(self.data_store)
      Email.new("buy_stock", self.data_store, self.current_store)
      self.data_store = nil
    end
  end

  def select_stock_to_buy
    Action.new(
      prompt: "Please enter the fullname of the desired SKU:",
      error: "Sorry, there is no record of that SKU.",
      validators: [lambda { |v| Sku.find_by_fullname(v) }],
      behaviors: [lambda { |v| choose_quantity_of_stock_to_buy(Sku.find_by_fullname(v)) }],
    )
  end

  def choose_quantity_of_stock_to_buy(sku)
    Action.new(
      prompt: "The item #{sku.fullname} has the wholesale price of $#{sku.wholesale_price}.\nPlease enter the quantity you want to purchase:",
      error: "Sorry, that's not a quantity.",
      validators: [lambda { |v| v.to_i > 0 }],
      behaviors: [lambda { |v|
        self.current_store.get_stock(sku, v.to_i)
        puts "Ok, we'll process your order of #{v} #{sku.fullname}(s)!"
      }],
    )
  end

  def update_price_of_some_item
    Action.new(
      prompt: "Please enter the fullname of the item to update:",
      error: "Sorry, there's not a sellable produce.",
      validators: [lambda { |v| Sku.find_by_fullname(v) }],
      behaviors: [lambda { |v| set_price_of_item(Sku.find_by_fullname(v)) }],
    )
  end

  def set_price_of_item(sku)
    Action.new(
      prompt: "Please enter the amount in dollars you will charge for #{sku.fullname}(s)",
      error: "Sorry, that's not a dollar ammount.",
      validators: [lambda { |v|
        if v[0] == "$"
          s = v[1...v.length]
        else
          s = v
        end
        ("0" + s).to_f > 0
      }],
      behaviors: [lambda { |v|
        if v[0] == "$"
          s = v[1...v.length]
        else
          s = v
        end
        s = ("0" + s).to_f.round(2)
        self.current_store.set_price_for_sku_here(sku, s)
        puts "OK, you now charge $#{s} for #{sku.fullname}(s)."
      }],
    )
  end

  def check_stock_count
    Action.new(
      prompt: "Please enter the fullname of the SKU you want to check:",
      error: "Sorry, there is no record of that SKU.",
      validators: [lambda { |v| Sku.find_by_fullname(v) }],
      behaviors: [lambda { |v|
        sku = Sku.find_by_fullname(v)
        puts "There are #{self.current_store.stock_count(sku)} #{sku.fullname}(s) in stock."
      }],
    )
  end

  def report_lsd_items
    Action.new(
      prompt: "Please enter the fullname of the item:",
      error: "Sorry, there is no record of that SKU.",
      validators: [lambda { |v| Sku.find_by_fullname(v) }],
      behaviors: [lambda { |v| remove_lsd_item(Sku.find_by_fullname(v)) }],
    )
  end

  def remove_lsd_item(sku)
    Action.new(
      prompt: "Please enter the quantity of #{sku.fullname} that are lost, damaged, or stolen:",
      error: "Sorry, that's not a quantity.",
      validators: [lambda { |v| v.to_i > 0 }],
      behaviors: [lambda { |v|
        self.current_store.report_lost_or_stolen(sku, v.to_i)
        puts "Thank you, we've updated inventory."
      }],
    )
  end

  def choose_item_to_find
    Action.new(
      prompt: "Please enter the fullname of the SKU you want to find:",
      error: "Sorry, there is no record of that SKU.",
      validators: [lambda { |v| Sku.find_by_fullname(v) }],
      behaviors: [lambda { |v| find_item_elsewhere(Sku.find_by_fullname(v)) }],
    )
  end

  def find_item_elsewhere(sku)
    Action.new(
      prompt: "Please enter the quantity of #{sku.fullname}(s) that you want to find:",
      error: "Sorry, that's not a quantity.",
      validators: [lambda { |v| v.to_i > 0 }],
      behaviors: [lambda { |v|
        other_locations = self.current_store.find_elsewhere(sku, v.to_i)
        if other_locations.length != 0
          display_strings = other_locations.collect { |location| "#{location.name} at #{location.address} has #{location.stock_count(sku)}." }
          puts display_as_numbered_list(header: "Here are the locations where you can find this item:", strings: display_strings)
        else
          puts "Sorry, all other stores are out of stock."
        end
      }],
    )
  end

  def request_goods_from_other_store
    Action.new(
      prompt: "Please enter the fullname of the SKU you want to request:",
      error: "Sorry, there is no record of that SKU.",
      validators: [lambda { |v| Sku.find_by_fullname(v) }],
      behaviors: [lambda { |v| request_this_good_from_other_store(Sku.find_by_fullname(v)) }],
    )
  end

  def request_this_good_from_other_store(sku)
    Action.new(
      prompt: "Please enter the quantity of #{sku.fullname}(s) that you want to request:",
      error: "Sorry, that's not a quantity.",
      validators: [lambda { |v| v.to_i > 0 }],
      behaviors: [lambda { |v| request_number_of_good_from_other_store(sku, v.to_i) }],
    )
  end

  def request_number_of_good_from_other_store(sku, quantity)
    Action.new(
      prompt: "Please enter the address of the store you want the goods from:",
      error: "Sorry, no location with that address has those goods.",
      validators: [lambda { |v|
        location = Location.find_location_by_address(v)
        if location
          location.in_stock?(sku, quantity)
        else
          false
        end
      }],
      behaviors: [lambda { |v|
        location = Location.find_location_by_address(v)
        self.current_store.request_stock_from(sku, quantity, location)
        hash = { sku.id => quantity }
        Email.new("request_from_store", hash, self.current_store)
        puts "The requested stock has been transferred."
      }],
    )
  end

  def view_catalog
    puts display_as_numbered_list(
      header: "Your store may order and sell the following items:",
      strings: Sku.all.collect { |sku| "#{sku.fullname}, MSRP: #{sku.msrp}" },
    )
  end

  def display_inventory
    to_print = Sku.all.each_with_object({}) do |sku, hash|
      if current_store.in_stock?(sku, 1)
        hash[sku.fullname] = [current_store.stock_count(sku), sku.sku_locations.find { |sl| sl.location == current_store }.locations_price]
      end
    end
    if to_print.keys.count > 0
      puts display_as_numbered_list(
        header: "Your store has the following inventory:",
        strings: to_print.collect { |sku_name, quantity_price_pair| "#{sku_name}--#{quantity_price_pair[0].to_s}--sold for $#{quantity_price_pair[1]}/per unit" },
      )
    else
      puts "You have no rights to own a store"
    end
  end

  def process_user_purchase
    sku_hash = self.current_store.inventory_as_hash

    get_sku_quantity_hash_from_user(header_1: "Please enter the line number of the purchased product:",
                                    header_2: "Please enter the quantity purchased:",
                                    display_hash: sku_hash,
                                    output_hash: {})

    if self.data_store != nil
      total = self.current_store.made_sale(self.data_store)
      Email.new("sale_made", self.data_store, self.current_store)
      self.data_store = nil

      puts "The total price of the sale is $#{total.round(2)}."
    end
  end

  def verify_return_id
    Action.new(
      prompt: "Please provide the purchase id to verify past purchase:",
      error: "Sorry, that's not an id we have on record.",
      validators: [lambda { |v| Location.find_purchase_location_by_id(v.to_i) }],
      behaviors: [lambda { |v| process_user_return(v.to_i) }],
    )
  end

  def process_user_return(id)
    sku_hash = Purchase.find(id).purchase_items.each_with_object({}) do |stock, hash|
      if hash.key?(stock.sku.id)
        hash[stock.sku.id] += 1
      else
        hash[stock.sku.id] = 1
      end
    end

    get_sku_quantity_hash_from_user(header_1: "Please enter the line number of the returned product:",
                                    header_2: "Please enter the quantity returned:",
                                    display_hash: sku_hash,
                                    output_hash: {})

    if self.data_store != nil
      total = self.current_store.return_items(id, self.data_store)
      self.data_store = nil
      puts "The total amount returned is $#{total.round(2)}."
    end
  end
end
