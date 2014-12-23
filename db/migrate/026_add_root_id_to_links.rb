Sequel.migration do
  change do
    alter_table :object_data_items do
      add_column :root_id, Integer
      add_column :rule_id, Integer
    end
    add_index :object_data_items, [:root_id]
    add_index :object_data_items, [:rule_id]
  end
end
