class Location < ActiveRecord::Base
  has_many :skus, through: :stock
  has_many :stock
  has_many :sku_locations

  def initialize(hash)
    super(hash)
    if Location.last == nil
      future_id = 1
    else
      future_id = Location.last.id + 1
    end
    Sku.all.each do |sku|
      SkuLocation.create(sku_id: sku.id, location_id: future_id, total_sold: 0)
    end
  end

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
    end
  end

  def cart_in_stock(skus_hash)
    skus_hash.all? do |sku_id, quantity|
      self.in_stock?(Sku.find(sku_id), quantity)
    end
  end

  def made_sale(skus_hash)
    all_in_stock = cart_in_stock(skus_hash)
    if all_in_stock
      purchase = Purchase.create(location_id: self.id)
      skus_hash.each do |sku_id, quantity|
        quantity.times do
          stock_item = Stock.all.find { |stock_item| stock_item.location == self && stock_item.sku.id == sku_id }
          PurchaseItem.create(sku_id: sku_id, purchase_price: stock_item.sale_price, purchase_id: purchase.id)
          stock_item.delete
        end
      end
    end
  end

  def return_items
  end

  def self.find_location_by_address(address)
    Location.all.find { |location| location.address == address }
  end

  def set_price_for_sku_here(sku, price)
    selected = self.stock.select{|stock_item| stock_item.sku == sku}
    selected.each{|stock_item| stock_item.sale_price = price}
  end

end
