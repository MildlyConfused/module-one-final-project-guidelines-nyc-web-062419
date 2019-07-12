class Purchase < ActiveRecord::Base
  belongs_to :location
  has_many :purchase_items
  has_many :skus, through: :purchase_items


end
