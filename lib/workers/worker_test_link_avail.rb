class WorkerTestLinkAvail
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].test_link_avail!
  end
end







