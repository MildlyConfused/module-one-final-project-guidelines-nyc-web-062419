class SkuLocation < ActiveRecord::Base
  belongs_to :sku
  belongs_to :location
end
