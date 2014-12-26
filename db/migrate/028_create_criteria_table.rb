Sequel.migration do
  change do
    create_table :criteria do
      primary_key :id
      String :sphere
      String :label
      String :name
    end
    add_index :criteria, [:sphere]
    add_index :criteria, [:name]
  end
end
