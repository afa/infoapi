Sequel.migration do
  change do
    alter_table :roots do
      add_column :sitemap_session_id, Integer
    end
    add_index :roots, [:sitemap_session_id]
  end
end
