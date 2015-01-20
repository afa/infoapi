Sequel.migration do
  change do
    alter_table :fake_api_items do
      add_column :sphere, String, null: false, default: 'general'
      add_column :kind, String, null: false, default: 'no-kind'
      add_column :active, FalseClass, null: false, default: true
      add_index :sphere
      add_index :kind
      add_index :active
    end
  end
end
