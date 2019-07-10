class PurchaseItem < ActiveRecord::Base
  belongs_to :purchase
  belongs_to :sku
end
