Sequel.migration do
  change do
    alter_table :indexes do
      add_column :url, String
      add_column :label, String
    end
    add_index :indexes, [:url]
  end
end
