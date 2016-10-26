class GenerateReportsJob < ActiveJob::Base
  queue_as :report

  def perform(*args)
    # Do something later
  end
end
