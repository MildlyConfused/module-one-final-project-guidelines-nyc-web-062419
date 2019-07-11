class AddMsrpToSku < ActiveRecord::Migration[5.0]
  def change
    add_column :skus, :msrp, :float
  end
end
