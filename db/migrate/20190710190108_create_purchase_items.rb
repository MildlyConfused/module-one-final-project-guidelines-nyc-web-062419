class CreatePurchaseItems < ActiveRecord::Migration[5.0]
  def change
    create_table :purchase_items do |t|
      t.integer :sku_id
      t.integer :purchase_id
      t.integer :purchase_price
    end
  end
end
