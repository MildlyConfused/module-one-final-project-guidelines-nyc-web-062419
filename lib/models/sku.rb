class Sku < ActiveRecord::Base
  has_many :locations, through: :stock
  has_many :stock
  has_many :purchase_items
  has_many :purchases, through: :purchase_items
  has_many :sku_locations

  def initialize(hash)
    super(hash)
    if Sku.last == nil
      future_id = 1
    else
      future_id = Sku.last.id + 1
    end
    Location.all.each do |location|
      SkuLocation.create(sku_id: (future_id), location_id: location.id, total_sold: 0)
    end
  end

  def fullname
    self.brand + ": " + self.name
  end

  
  def self.find_by_fullname(fullname)
    array = fullname.split(": ")
    brand = array[0]
    name = array[1]
    Sku.find_by(name: name, brand: brand)
  end
end
