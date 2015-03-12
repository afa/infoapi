Sequel.migration do
  change do
    alter_table :refs do
      add_column :photo, String
      add_column :crypto_hash, String
      add_column :label, String
    end
  end
end
