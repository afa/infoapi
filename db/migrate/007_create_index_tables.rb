Sequel.migration do
  change do
    create_table :roots do
      primary_key :id
      String :sphere
      String :name
    end
    add_index :roots, :sphere
    add_index :roots, :name

    create_table :indexes do
      primary_key :id
      Integer :parent_id
      Integer :root_id
      String :json, text: true
    end
    add_index :indexes, :parent_id
    add_index :indexes, :root_id

    create_table :refs do
      primary_key :id
      String :url
      Integer :index_id
      Integer :duplicate_id 
      Boolean :is_empty
    end
    add_index :refs, :url
    add_index :refs, :is_empty

    create_table(:sitemap_objects) do
      primary_key :id
      String :sphere, null: false
      String :full_id, null: false
      Timestamp :parse_date, null: false
      Integer :index_position, null: false
      Integer :ext_id, null: false
    end
    add_index :sitemap_objects, :sphere
    add_index :sitemap_objects, :ext_id
    add_index :sitemap_objects, :index_position
  end
end
