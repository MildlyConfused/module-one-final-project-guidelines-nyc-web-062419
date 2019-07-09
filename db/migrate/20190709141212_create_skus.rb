class CreateSkus < ActiveRecord::Migration[5.0]
  def change
    create_table :skus do |t|
      t.string :name
      t.float :wholesale_price
    end
  end
end
