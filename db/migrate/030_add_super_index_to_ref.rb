Sequel.migration do
  change do
    alter_table :refs do
      add_column :super_index_id, Integer
    end
    add_index :refs, [:super_index_id]
  end
end
