class WorkerTestLinkAvail
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start empty refs for prduction #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    return true unless prod
    logger.info "production #{prod.inspect}"
    prod.test_link_avail!
    logger.info "done production #{production_id}"
  end
end







