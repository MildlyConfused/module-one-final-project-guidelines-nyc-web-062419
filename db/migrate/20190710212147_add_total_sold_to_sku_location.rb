class AddTotalSoldToSkuLocation < ActiveRecord::Migration[5.0]
  def change
    add_column :sku_locations, :total_sold, :integer
  end
end
