class Sku < ActiveRecord::Base
  has_many :locations, through: :stock
  has_many :stock

  def fullname
    self.brand + ": " + self.name
  end

  def self.find_by_fullname(fullname)
    array = fullname.downcase.split(": ")
    brand = array[0]
    name = array[1]
    Sku.find_by(name: name.downcase, brand: brand.downcase)
  end
end
