Sequel.migration do
  change do
    alter_table :refs do
      add_column :json, String, text: true
      add_column :rule_id, Integer, null: false
      # add_column :sitemap_session_id, Integer, null: false
    end
    add_index :refs, :rule_id
    add_index :refs, :sitemap_session_id
  end
end
