Sequel.migration do
  change do
    alter_table :indexes do
      add_column :leaf, TrueClass
      add_column :empty, TrueClass
    end
    add_index :indexes, [:leaf]
    add_index :indexes, [:empty]
  end
end
