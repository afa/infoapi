Sequel.migration do
  change do
    create_table :object_data_items do
      primary_key :id
      String :photo
      String :label
      String :url
      Integer :index_id
    end
    add_index :object_data_items, [:index_id]
  end
end
