class Revpro::CLI::Reporter
  REPORT_HOST = "http://localhost:3000"
  # TELEMETRY_URL = "https://revpro-telemetry.herokuapp.com/submit"

  extend Revpro::CLI::Utils::ClassMethods

  def initialize(event_name:, event_data: {}, event_object: {})
    @config = self.class.global_config_data    
    @event_object = event_object
    @event_name = event_name
    @event_data = event_data
    send("#{@event_name}_event")
  end

  def deliver_event(payload)
    begin
      con = Faraday.new(REPORT_HOST)
      res = con.post('/revpro-cli-events', payload)      
      # binding.pry
    rescue
    end
  end

  def log_event(payload)
    # Write a json file in .revpro for this event
    # self.class.global_config_data
    # binding.pry
    FileUtils.mkdir_p("#{self.class.global_config_dir}/.events/")
    File.open("#{self.class.global_config_dir}/.events/event.json", "w") do |f|
      f.write(payload.to_json)
    end
  end

  def submit_event
    event_payload = payload.merge({
      event_data: {
        lab_name: @event_data[:lab_name],
        branch_name: @event_data[:branch_name],
        branch_url: @event_data[:branch_url],
        project_name: @config[:current_project],
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
    # TELEMETRY_URL = "https://revpro-telemetry.herokuapp.com/submit"   
    log_event(event_payload)
    deliver_event(event_payload)
  end

  def payload
    @payload ||= {
      event_name: @event_name,
      event_actor: {
        github_username: @config[:github_username],
        github_email: @config[:git_email],
        revpro_email: @config[:revpro_email]
      },
      event_timestamp: Time.now
    }
  end
end