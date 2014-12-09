Sequel.migration do
  change do
    alter_table :indexes do
      add_column :rule_id, Integer
      add_column :filter, String
      add_column :value, String
    end
    add_index :indexes, [:rule_id]
    add_index :indexes, [:filter]
    add_index :indexes, [:value]
  end
end
