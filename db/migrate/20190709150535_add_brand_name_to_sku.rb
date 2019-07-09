class AddBrandNameToSku < ActiveRecord::Migration[5.0]
  def change
    add_column :skus, :brand, :string
  end
end
