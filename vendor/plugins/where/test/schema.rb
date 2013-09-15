ActiveRecord::Schema.define(:version => 1) do

  create_table :items, :force => true do |t|
    t.column :name, :string
  end

  create_table :orders, :force => true do |t|
    t.column :item_id, :integer
    t.column :cost,    :integer
    t.column :country, :string
  end

end