Sequel.migration do
  change do
    create_table :test_applications do
      primary_key :id
      String :base_url, null: false
      String :label, null: false
    end
    add_index :test_applications, :base_url, unique: true
    add_index :test_applications, :label, unique: true
  end
end
