class Revpro::CLI::Commands::Submit < Revpro::CLI::Command
  extend Revpro::CLI::Utils::ClassMethods

  desc "Submit a lab"

  argument :lab_path, required: false, desc: "Path to lab. Default: ."

  def call(lab_path: nil, **)
    if !lab_path
      if !self.class.global_config_exists?
        puts "#{"Labs not set up yet!".colorize(:white).colorize(:background => :red)}"
        puts "Please run the revpro start command. See instructions at #{"https://revatu.re/revature-pt-student-guide".colorize(:blue)}\n\n"
        exit
      end
      repo = Git.open(self.class.global_config_data[:projects][self.class.global_config_data[:current_project]][:repo_path])
      lab_path = repo.current_branch
    end

    @lab = Revpro::CLI::Codelabs::RevproMultiple.new(lab_path: lab_path, command: "submit")
    @lab.submit
  end
end
