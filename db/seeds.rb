



5.times do
    Location.create(name: "CVS", address: Faker::Address.street_address, email_address: Faker::Internet.email)
end

8.times do
    whole = (rand * 10).round(2)
    retail = (whole * 2.14).round(2)
    Sku.create(brand:Faker::Company.name, name: Faker::Commerce.product_name, wholesale_price: whole, msrp: retail)
end

Sku.all.each do |sku|
    Location.all.each do |loc|

        init_stock = (10..40).to_a.sample

        init_stock.times do
            Stock.create(sku_id: sku.id, location_id: loc.id)
        end

    end
end

