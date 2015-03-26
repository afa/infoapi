Sequel.migration do
  change do
    add_index :refs, [:index_id]
  end
end
