class CreateSkuLocations < ActiveRecord::Migration[5.0]
  def change
    create_table :sku_locations do |t|
      t.integer :sku_id
      t.integer :location_id
      t.float :locations_price
    end
  end
end
