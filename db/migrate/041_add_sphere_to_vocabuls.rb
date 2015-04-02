Sequel.migration do
  change do
    alter_table :vocabulary do
      add_column :sphere, String
      add_column :lang, String
      drop_column :schema #, String
    end
    add_index :vocabulary, [:sphere]
    add_index :vocabulary, [:lang]
  end
end
