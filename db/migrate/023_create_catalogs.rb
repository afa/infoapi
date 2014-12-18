Sequel.migration do
  change do
    create_table :catalogs do
      primary_key :id
      String :path, null: false
    end
    add_index :catalogs, [:path]
  end
end
