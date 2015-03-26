class WorkerFinish
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start finish for prduction #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    return true unless prod
    logger.info "production #{prod.inspect}"
    prod.finish!
    logger.info "done production #{production_id}"
  end
end








