Sequel.migration do
  change do
    create_table :photos do
      primary_key :id
      Integer :sitemap_object_id
      String :kind
      String :url
    end
    add_index :photos, :sitemap_object_id
  end
end
