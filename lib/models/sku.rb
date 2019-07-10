class Sku < ActiveRecord::Base
  has_many :locations, through: :stock
  has_many :stock
  has_many :purchase_items
  has_many :purchases, through: :purchase_items

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
