class Revpro::CLI::Commands::Test < Revpro::CLI::Command
  desc "Run the test suite for a lab."
  argument :lab_path, desc: "Path to a lab directory."

  example [
    "lab-1          # Start lab-1 from within the root directory",
    "topic-1/lab-1  # Start lab-1 in folder topic-1",
  ]

  def call(lab_path: ".", **)
    lab_path = "#{File.expand_path(lab_path.strip)}"

    @lab = Revpro::CLI::Codelabs::RevproMultiple.new(lab_path: lab_path)
    @lab.test
  end
end
