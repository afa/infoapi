Sequel.migration do
  change do
    create_table :sitemap_rules do
      primary_key :id
      foreign_key :original_rule_id, :rules
      String :name
      String :label
      String :sphere
      String :param
      String :lang
      foreign_key :root_id, :roots
    end
    add_index :sitemap_rules, [:root_id]
    add_index :sitemap_rules, [:original_rule_id]
    add_index :sitemap_rules, [:sphere]
    add_index :sitemap_rules, [:param]
    add_index :sitemap_rules, [:lang]
    alter_table :productions do
      add_column :param, String
    end
    add_index :productions, [:param]
    alter_table :refs do
      add_foreign_key :root_id, :roots
    end
    add_index :refs, [:root_id]
  end
end
