class Stock < ActiveRecord::Base
  belongs_to :sku
  belongs_to :location

  def sale_price

    SkuLocation.all.find{|sl| sl.sku == self.sku && sl.location == self.location}

  end

end
