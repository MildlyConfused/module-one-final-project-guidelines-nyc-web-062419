class CreateStocks < ActiveRecord::Migration[5.0]
  def change
    create_table :stocks do |t|
      t.float :purchase_price
      t.float :sale_price
      t.integer :location_id
      t.integer :sku_id
    end
  end
end
