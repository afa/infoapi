Sequel.migration do
  change do
    create_table :fake_api_items do
      primary_key :id
      String :url
      String :content
      String :description

      index :url, unique: true
    end
  end
end
