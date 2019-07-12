class Stock < ActiveRecord::Base
  belongs_to :sku
  belongs_to :location

  attr_reader :purchase_price

  def initialize(hash)
    super(hash)
    @purchase_price = Sku.find(sku_id).wholesale_price
    # The record of the price paid to the manufacturer.

  end

  def sale_price
    SkuLocation.all.find { |sl| sl.sku == self.sku && sl.location == self.location }.locations_price
  end
end
