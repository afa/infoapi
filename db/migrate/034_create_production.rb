Sequel.migration do
  change do
    create_table :productions do
      primary_key :id
      String :state
      String :sphere
      String :step_params, text: true
      foreign_key :sitemap_session_id, :sitemap_sessions
      foreign_key :root_id, :roots
      foreign_key :rule_id, :rules
      foreign_key :parent_id, :productions
    end
    add_index :productions, [:root_id]
    add_index :productions, [:rule_id]
    add_index :productions, [:sitemap_session_id]
    add_index :productions, [:parent_id]
  end
end
