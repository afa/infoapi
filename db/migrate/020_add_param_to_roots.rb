Sequel.migration do
  change do
    alter_table :roots do
      add_column :param, String
    end
    add_index :roots, [:param]
  end
end
