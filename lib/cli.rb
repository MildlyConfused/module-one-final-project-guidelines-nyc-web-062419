class Cli
  attr_accessor :current_store, :body

  def initialize
    @current_store = nil
  end

  # Actions
  def self.actions
    @@actions_array
  end

  @@actions_array = ["Buy Stock", "Check Stock Count", "Find item elsewhere", "Report goods lost, stolen or damaged", "Request goods from another store", "View Carried Items", "Check full inventory"]

  def buy_stock
    puts "Please enter the fullname of the SKU"
    sku = Sku.find_by_fullname(gets.chomp)
    puts "Please enter the quantity for purchase"
    quantity = gets.chomp.to_i
    puts "Please enter the price you will charge for #{sku.fullname}"
    sell_price = gets.chomp.to_f
    current_store.get_stock(sku, quantity, sell_price)
    Email.new("buy_stock", Email.purchased_goods_template, sku, quantity, current_store)
    puts "Thank you for your purchase of #{quantity} #{sku.fullname}(s)"
  end

  def check_stock_count
    puts "Please enter the fullname of the SKU"
    sku = Sku.find_by_fullname(gets.chomp)
    puts "There are #{current_store.stock_count(sku)} #{sku.fullname}(s) in stock"
  end

  def find_item_elsewhere
    puts "Please enter the fullname of the SKU"
    sku = Sku.find_by_fullname(gets.chomp)
    puts "Please enter the required quantity"
    quantity = gets.chomp.to_i
    other_locations = current_store.find_elsewhere(sku, quantity)
    if other_locations.length != 0
      puts "Here are some other locations where you can find this item:"
      other_locations.each do |location|
        puts "#{location.name} located at: #{location.address}"
      end
    else
      puts "Sorry all stores are out of stock"
    end
  end

  def report_lsd_items
    puts "Please enter the fullname of the SKU to report it"
    sku = Sku.find_by_fullname(gets.chomp)
    puts "How many would you like to report"
    quantity = gets.chomp.to_i
    current_store.report_lost_or_stolen(sku, quantity)
    if current_store.stock_count(sku) <= 5
      Email.new("low_stock", Email.purchased_goods_template, sku, quantity, current_store)
    end
    puts "Thank you. We've updated our inventory"
  end

  def request_goods_from_other_store
    puts "Please enter the fullname of the SKU you want"
    sku = Sku.find_by_fullname(gets.chop)
    puts "Please enter the quantity that you want"
    quantity = gets.chomp.to_i
    puts "Please enter the address of the store you want the goods from"
    from_location = Location.find_location_by_address(gets.chop)
    current_store.request_stock_from(sku, quantity, from_location)
    Email.new("request_from_store", Email.purchased_goods_template, sku, quantity, current_store, from_location)
  end

  def view_carried_items
    puts "\nYour store may offer the following items:"
    Sku.all.each.with_index { |sku, i| puts "#{i + 1}. #{sku.fullname}" }
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

  # Main Flow
  def greet
    puts "Welcome Employee!"
    puts "At any time enter 'help' to see a list of possible commands or 'exit' to exit the application"
  end

  def get_location
    puts "Please enter the address of the store location:"
    status = true
    while status
      address = gets.chomp
      if Location.find_location_by_address(address)
        self.current_store = Location.find_location_by_address(address)
        status = false
      elsif address == "exit"
        exit
      else
        puts "\nStore not found. Please enter a valid address\n"
        puts "_________________________________________\n"
      end
    end
  end

  def show_actions
    puts "\nCurrent Store is #{current_store.name} located at #{current_store.address}.\nHere are your possible store actions:"
    Cli.actions.each_with_index do |action, i|
      puts "#{i + 1}. #{action}"
    end
    choose_action
  end

  def choose_action
    puts "\nSelect a number:"
    input = gets.chomp
    case input.downcase
    when "1"
      #Buy Stock
      buy_stock
    when "2"
      #Check stock count
      check_stock_count
    when "3"
      find_item_elsewhere
    when "4"
      report_lsd_items
    when "5"
      request_goods_from_other_store
    when "6"
      view_carried_items
    when "7"
      display_inventory
    when "exit"
      exit
    when "change store"
      get_location
    when "help"
      show_actions
    else
      #something else
      puts "\nSorry, that's not a valid input.\n"
      puts "___________________________________________\n"
    end
  end
end
