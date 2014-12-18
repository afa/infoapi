Sequel.migration do
  change do
    alter_table :sitemap_sessions do
      add_column :operation_type, Integer
    end
  end
end
