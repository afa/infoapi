Sequel.migration do
  change do
    create_table(:sitemap_sessions) do
      primary_key :id
      String :state
      String :errors, text: true
      DateTime :generation_time
    end
    alter_table :refs do
      add_column :sitemap_session_id, Integer
    end
    alter_table :sitemap_objects do
      add_column :sitemap_session_id, Integer
    end
  end
end
