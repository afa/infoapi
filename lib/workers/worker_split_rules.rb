class WorkerSplitRules
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start split rules for prduction #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    return true unless prod
    logger.info "production #{prod.inspect}"
    prod.split_rules!
    logger.info "done production #{production_id}"
  end
end
