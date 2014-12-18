Sequel.migration do
  change do
    alter_table :sitemap_sessions do
      add_column :params, String, text: true
      add_column :updated_at, DateTime
    end
  end
end
