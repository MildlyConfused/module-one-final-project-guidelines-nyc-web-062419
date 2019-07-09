class Location < ActiveRecord::Base
  has_many :skus, through: :stock
  has_many :stock

  def get_stock(sku, quantity = 1, sale_price)
    #Buy given quantity of an item
    quantity.times do
      Stock.create(location_id: self.id, sku_id: sku.id, purchase_price: sku.wholesale_price, sale_price: sale_price)
    end
  end

  def all_skus
    Sku.all
  end

  def in_stock?(sku, quantity)
    stock_count(sku) >= quantity
  end

  def stock_count(sku)
    Stock.all.select { |stock_item| stock_item.sku == sku && stock_item.location_id == self.id }.count
  end

  def find_elsewhere(sku, quantity = 1)
    #See if the item is available elsewhere (if OOS)
    location_list = Location.all.select { |location| location.in_stock?(sku, quantity) }
    return location_list - [self]
  end

  def decrease_stock(sku, quantity)
    #Remove goods from stock because they were lost, damaged or stolen
    if in_stock?(sku, quantity)
      to_delete = self.stock.select { |stock_item| stock_item.sku == sku }
      quantity.times do |i|
        Stock.delete(to_delete[i].id)
      end
      # else
      #   puts "Didn't work"
    end
  end

  def report_lost_or_stolen(sku, quantity)
    decrease_stock(sku, quantity)
  end

  def request_stock_from(sku, quantity, from_location)
    #A Location can request (and receive) stock from others
    if from_location.in_stock?(sku, quantity)
      to_move = from_location.stock.select { |stock_item| stock_item.sku == sku }
      quantity.times do |i|
        to_move[i].update(location_id: self.id)
      end
    else
      puts "#{from_location.name} at #{from_location.address} does not have enough stock of #{sku.fullname}"
    end
  end

  def self.find_location_by_address(address)
    Location.all.find { |location| location.address == address }
  end
end
