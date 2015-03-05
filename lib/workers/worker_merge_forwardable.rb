class WorkerMergeForwardable
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].merge_forwardable!
  end
end





