class WorkerMergeForwardable
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start merge forwardables for prduction #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    return true unless prod
    logger.info "production #{prod.inspect}"
    prod.merge_forwardable!
    logger.info "done production #{production_id}"
  end
end





