ActiveRecord::Schema.define(:version => 0) do
  create_table :datetime_strs, :force => true do |t|
    t.column "datetime_str", :string
  end
  create_table :valid_unlike_strs, :force => true do |t|
    t.column "str", :string
  end
  create_table :no_hankana_str_by_selves, :force => true do |t|
    t.column "str", :string
  end
  create_table :no_hankana_strs, :force => true do |t|
    t.column "str", :string
  end
end
