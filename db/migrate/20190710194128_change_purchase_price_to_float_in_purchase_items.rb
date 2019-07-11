class ChangePurchasePriceToFloatInPurchaseItems < ActiveRecord::Migration[5.0]
  def change
    change_column :purchase_items, :purchase_price, :float
  end
end
