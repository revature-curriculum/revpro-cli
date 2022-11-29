class Revpro::CLI::Reporter  
  extend Revpro::CLI::Utils::ClassMethods

  def initialize(event_name:, event_data: {})
    @config = self.class.global_config_data
    @event_name = event_name
    @event_data = event_data
    send("#{@event_name}_event")
  end

  def submit_event
    event_payload = payload.merge({
      event_data: {
        lab_name: @event_data[:lab_name],
        branch_name: @event_data[:branch_name],
        branch_url: @event_data[:branch_url]
      }
    })

    # Sends the payload to Res
    # From RES
      # Admin will see that there is a submission for this lab to review.
      # They will click start review
      # Res will automate opening up a pull request from the github_username of the student and their lab branch to the canonical repo
      # It will then open the pull request URL in their browser
      # Github actions will run the test suite for the students lab branch within the PR interface
      # they admin will then go to the "Start Review" for the PR
      # they can review the code and the test run results
      # by approving the PR, they are grading the lab as a pass
      # by rejecting the PR, they are grading the lab as a fail
      # The PR is only closed on a passing grade but never merged
      # if they failed, what's the workflow for resubmitting / re-reviewing...

    # TODO
      # have CLI submit payload to Res
      # configure res to receive this payload and setup the submission / start review
      # upon start review
        # open the PR
      # configure Res to listen to payloads from Github
      # finish the workflow
      
    binding.pry
  end

  def payload
    @payload ||= {
      event_name: @event_name,
      github_username: @config[:github_username],
      event_timestamp: Time.now
    }
  end
end