class Sku < ActiveRecord::Base
  has_many :locations, through: :stock
  has_many :stock
end
