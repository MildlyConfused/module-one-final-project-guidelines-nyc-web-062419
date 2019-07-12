class RemoveSalePriceFromStocks < ActiveRecord::Migration[5.0]
  def change
    remove_column :stocks, :sale_price
  end
end
