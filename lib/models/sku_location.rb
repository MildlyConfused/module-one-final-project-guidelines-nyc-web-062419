class SkuLocation < ActiveRecord::Base
  belongs_to :sku
  belongs_to :location

  #   def initialize(hash)
  #     super(hash)
  #     binding.pry
  #     self.locations_price = sku..msrp
  #   end
end
