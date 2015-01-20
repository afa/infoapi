Sequel.migration do
  change do
    create_table :fake_api_launches do
      primary_key :id
      DateTime :created_at, null: false
      String :url, null: false
      String :response, text: true
      foreign_key :fake_api_item_id, :fake_api_items
    end
  end
end
