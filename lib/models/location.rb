class Location < ActiveRecord::Base
  has_many :skus, through: :stock
  has_many :stock
end
