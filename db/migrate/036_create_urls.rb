Sequel.migration do
  change do
    create_table :sitemap_urls do
      primary_key :id
      DateTime :created_at
      String :url
      foreign_key :sitemap_session_id, :sitemap_sessions
      foreign_key :rule_id, :rules
    end
    add_index :sitemap_urls, [:sitemap_session_id]
    add_index :sitemap_urls, [:rule_id]
    add_index :sitemap_urls, [:url]
    create_table :vocabulary do
      primary_key :id
      String :schema
      String :name
      String :kind
      String :label
      DateTime :created_at
    end
    add_index :vocabulary, [:schema, :kind]
    add_index :vocabulary, [:name]
  end
end
