Sequel.migration do
  change do
    alter_table :object_data_items do
      add_column :crypto_hash, String
    end
    add_index :object_data_items, [:crypto_hash]
  end
end
